// wload: the weight loader.
// Reads the weight stream (w_img). For each block it stores 8 parameter words in registers
// and K weight words in the idle half of wb_pair, then waits to be swapped in. It owns the
// ping-pong state.
//
// Ports
//   name       dir    width    meaning
//   clk        in     1        the one clock
//   rst        in     1        synchronous, active high
//   start      in     1        pulse; begin a layer: blocks_left = n_tiles
//   k          in     11       K, 1 to 1,024; stable while busy
//   n_tiles    in     16       N_T; stable while busy
//   s_valid    in     1        s_axis_tvalid & dest
//   s_data     in     64       s_axis_tdata
//   s_ready    out    1        high only in L_PARAM and L_WGT; a word moves when s_valid & s_ready
//   swap       in     1        pulse from layer_fsm: flip active, clear nxt_valid
//   active     out    1        the half of wb_pair the array reads; writes go to ~active
//   nxt_valid  out    1        the idle half and the NEXT parameter set hold a complete block
//   wb_we      out    1        write enable into wb_pair
//   wb_waddr   out    AW       write address, k
//   wb_wdata   out    64       weight word
//   cur_bias   out    8 x 32   bias of channel c from the set paired with active; [c] = channel c
//   nxt_bias   out    8 x 32   bias of channel c from the set paired with ~active
//   cur_m0     out    8 x 16   M0 of channel c from the set paired with active
//   cur_sh     out    8 x 6    s of channel c from the set paired with active
//   AW         param  int      10; one half holds 2**AW = 1,024 words
//
// Behaviour
//   State: loader state, a word counter, blocks_left (16 bits), active, nxt_valid, and two
//   parameter sets, set 0 and set 1, each bias[8] (32 b), m0[8] (16 b), sh[8] (6 b).
//   Set number `active` is CURRENT; set number ~active is NEXT.
//   1. L_IDLE: s_ready = 0. On start: blocks_left <= n_tiles, word counter <= 0, go to L_PARAM.
//      start outside L_IDLE is ignored.
//   2. L_PARAM: s_ready = 1. Accepted word c (c = 0 to 7) fills channel c of set ~active:
//      bias = bits 31:0, m0 = bits 47:32, sh = bits 53:48. Bits 63:54 are ignored.
//      After 8 words: word counter <= 0, go to L_WGT.
//   3. L_WGT: s_ready = 1. Accepted word k is written to wb_pair at address k
//      (wb_we = 1, wb_waddr = k, wb_wdata = the word). After K words: nxt_valid <= 1,
//      blocks_left <= blocks_left - 1, go to L_HOLD.
//   4. L_HOLD: s_ready = 0. On swap: active <= ~active, nxt_valid <= 0; then go to L_PARAM
//      if blocks_left > 0, else L_IDLE.
//   5. swap only arrives in L_HOLD with nxt_valid high. A swap at any other time is ignored.
//   6. cur_* read set `active`, nxt_bias reads set ~active, combinationally from the
//      registers.
//
// Timing
//   s_ready may depend on state only, not on s_valid.
//   wb_we may be registered one cycle after the word is accepted, but nxt_valid must not
//   rise before the last weight write has reached wb_pair.
//   s_ready is low whenever nxt_valid is high, so the DMA stalls until the array moves on.
//   Stalls (s_valid low) anywhere inside the 8 + K words just pause the counter.
//   Reset: L_IDLE, active = 0, nxt_valid = 0, blocks_left = 0. Parameter sets need no reset.
//
// Resource target
//   No block RAM, no DSP. The two parameter sets live in flip-flops (2 x 8 x 54 bits).
//   Together with wb_pair: 4 RAMB36E1.
//
// Done when
//   tb/ctrl/wload/tb_wload.sv prints PASS and every assertion in it has fired at least once.
//
// Spec
//   docs/architecture.md, section 6.4. docs/contracts.md, Contract 2 (parameter word).
//   docs/verification.md, section 6.4.

module wload #(
  parameter int AW = 10
) (
  input  logic             clk,
  input  logic             rst,
  input  logic             start,
  input  logic [10:0]      k,
  input  logic [15:0]      n_tiles,
  input  logic             s_valid,
  input  logic [63:0]      s_data,
  output logic             s_ready,
  input  logic             swap,
  output logic             active,
  output logic             nxt_valid,
  output logic             wb_we,
  output logic [AW-1:0]    wb_waddr,
  output logic [63:0]      wb_wdata,
  output logic [7:0][31:0] cur_bias,
  output logic [7:0][31:0] nxt_bias,
  output logic [7:0][15:0] cur_m0,
  output logic [7:0][5:0]  cur_sh
);

endmodule
