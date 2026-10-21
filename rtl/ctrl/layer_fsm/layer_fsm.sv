// layer_fsm: the sequencer.
// Walks the tiles of a layer: issues one read address per cycle to ub and wb_pair, tells the
// mxu when words are valid and when to shift, and decides when to swap weight blocks.
//
// Ports
//   name           dir    width  meaning
//   clk            in     1      the one clock
//   rst            in     1      synchronous, active high; back to IDLE
//   start          in     1      pulse from regfile; begin a layer
//   m_tiles        in     16     M_T, 1 or more; stable while busy
//   k              in     11     K, 1 to 1,024; stable while busy
//   n_tiles        in     16     N_T, 1 or more; stable while busy
//   nxt_valid      in     1      from wload: a complete block waits in the idle half
//   can_take_tile  in     1      from res_buf: at least 8 entries free
//   last_sent      in     1      from out_fifo: the tlast word was accepted
//   ub_rd_addr     out    13     ub_base + k
//   wb_rd_addr     out    10     k
//   in_valid       out    1      to mxu and regfile: the read enable delayed RD_LAT cycles
//   shift_en       out    1      to mxu and regfile: high for 8 cycles in PRELOAD and SHIFT
//   bias_sel       out    2      bias mux source: 0 CURRENT, 1 NEXT, 2 or 3 zero
//   shift_idx      out    3      channel c during a shift burst, 0 to 7
//   swap           out    1      to wload: one-cycle pulse in SWAP
//   rb_discard     out    1      to res_buf: the burst now leaving the array is the preload
//   rb_last        out    1      to res_buf: the burst now leaving the array is the final tile
//   busy           out    1      to regfile: high in every state but IDLE
//   done_set       out    1      to regfile: pulse, sets STATUS.DONE
//   err_set        out    1      to regfile: pulse, sets STATUS.ERROR
//   fsm_state      out    8      to regfile: state code below, shown in STATUS[15:8]
//   ev_wait_wb     out    1      counter enable, CNT_WAIT_WB
//   ev_wait_out    out    1      counter enable, CNT_WAIT_OUT
//   ev_tile        out    1      counter enable, CNT_TILES
//   RD_LAT         param  int    2; read latency of ub and wb_pair
//   FLUSH_LAT      param  int    mxu_pkg::FLUSH_LAT
//   SHIFT_LAT      param  int    mxu_pkg::SHIFT_LAT
//
// Behaviour
//   State: the state register; counters nt, mt, k; ub_base (14 bits); a small counter for
//   FLUSH and for the 8 shift cycles; a first-block flag. last_mt = (mt == m_tiles - 1),
//   last_nt = (nt == n_tiles - 1). Outputs not named in a state are 0.
//   1. IDLE (code 0). busy = 0. On start: nt = mt = 0, ub_base = 0, first = 1; go to WAIT_BLK.
//   2. WAIT_BLK (1). ev_wait_wb = 1. When nxt_valid: go to SWAP.
//   3. SWAP (2). swap = 1 for one cycle. Next: PRELOAD if first (then clear first), else ACC.
//   4. PRELOAD (3). 8 cycles: shift_en = 1, shift_idx = 0 to 7, bias_sel = CURRENT,
//      rb_discard = 1. Then go to ACC.
//   5. ACC (4). k runs 0 to K-1, one per cycle: ub_rd_addr = ub_base + k, wb_rd_addr = k.
//      in_valid follows each read RD_LAT cycles later, so it lands with the data.
//      On entry, if ub_base + K > 8,192, pulse err_set; keep running, results are invalid.
//      After K reads: go to FLUSH.
//   6. FLUSH (5). Idle until FLUSH_LAT cycles have passed since the last in_valid of the
//      tile. Then go to HOLD.
//   7. HOLD (6). need_next = last_mt & ~last_nt. ev_wait_out = ~can_take_tile.
//      ev_wait_wb = need_next & ~nxt_valid. When can_take_tile and (nxt_valid or not
//      need_next): go to SHIFT.
//   8. SHIFT (7). 8 cycles: shift_en = 1, shift_idx = 0 to 7. bias_sel loads the bias of
//      the tile that runs next: CURRENT if not last_mt; NEXT if last_mt and not last_nt;
//      zero on the final tile. rb_last = 1 on the final tile. ev_tile = 1 on the 8th cycle.
//      Then:
//        not last_mt:             mt + 1, ub_base + K, go to ACC.
//        last_mt and not last_nt: nt + 1, mt = 0, ub_base = 0, go to SWAP.
//        final tile:              go to DRAIN.
//   9. DRAIN (8). When last_sent: done_set = 1 for one cycle, go to IDLE.
//   Never build an address with a multiplier; ub_base advances by adding K.
//
// Timing
//   Contract 4: in_valid never high during a burst; shift_en rises no earlier than
//   FLUSH_LAT cycles after the last in_valid; in_valid may resume the cycle after shift_en
//   falls.
//   bias_sel and shift_idx are aligned with shift_en, since bias_in enters with it.
//   rb_discard and rb_last are aligned with res_valid, which follows shift_en by SHIFT_LAT.
//   With SHIFT_LAT = 0 all of them are high with shift_en.
//   Read FLUSH_LAT and SHIFT_LAT from the parameters, never as literals.
//   Reset: IDLE, all outputs 0.
//
// Resource target
//   No DSP (confirms no multiplier was inferred), no block RAM.
//
// Done when
//   tb/ctrl/layer_fsm/tb_layer_fsm.sv prints PASS and its cover counters for all 12
//   transitions are nonzero.
//
// Spec
//   docs/architecture.md, section 6.6. docs/contracts.md, Contract 4.
//   docs/verification.md, section 6.10.

module layer_fsm #(
  parameter int RD_LAT    = 2,
  parameter int FLUSH_LAT = mxu_pkg::FLUSH_LAT,
  parameter int SHIFT_LAT = mxu_pkg::SHIFT_LAT
) (
  input  logic        clk,
  input  logic        rst,
  input  logic        start,
  input  logic [15:0] m_tiles,
  input  logic [10:0] k,
  input  logic [15:0] n_tiles,
  input  logic        nxt_valid,
  input  logic        can_take_tile,
  input  logic        last_sent,
  output logic [12:0] ub_rd_addr,
  output logic [9:0]  wb_rd_addr,
  output logic        in_valid,
  output logic        shift_en,
  output logic [1:0]  bias_sel,
  output logic [2:0]  shift_idx,
  output logic        swap,
  output logic        rb_discard,
  output logic        rb_last,
  output logic        busy,
  output logic        done_set,
  output logic        err_set,
  output logic [7:0]  fsm_state,
  output logic        ev_wait_wb,
  output logic        ev_wait_out,
  output logic        ev_tile
);

endmodule
