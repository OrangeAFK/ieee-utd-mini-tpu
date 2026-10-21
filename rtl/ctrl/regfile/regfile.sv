// regfile: the register file, an AXI4-Lite slave.
// Holds the layer configuration, turns a START write into a pulse, reports status, and
// counts events for the driver.
//
// Ports
//   name           dir  width  meaning
//   clk            in   1      the one clock
//   aresetn        in   1      synchronous, active low; this block's only reset (not rst)
//   s_axi_awaddr   in   8      write address; bits 1:0 are ignored
//   s_axi_awvalid  in   1
//   s_axi_awready  out  1
//   s_axi_wdata    in   32
//   s_axi_wstrb    in   4      ignored; every write is a full word
//   s_axi_wvalid   in   1
//   s_axi_wready   out  1
//   s_axi_bresp    out  2      always 2'b00, OKAY
//   s_axi_bvalid   out  1
//   s_axi_bready   in   1
//   s_axi_araddr   in   8      read address
//   s_axi_arvalid  in   1
//   s_axi_arready  out  1
//   s_axi_rdata    out  32
//   s_axi_rresp    out  2      always 2'b00, OKAY
//   s_axi_rvalid   out  1
//   s_axi_rready   in   1
//   start          out  1      pulse on a legal START write while busy is low
//   soft_reset     out  1      pulse on a CTRL write with bit 1 set
//   dest           out  1      level, CTRL.DEST
//   ub_wr_rst      out  1      pulse on a CTRL write with bit 3 set
//   m_tiles        out  16     M_TILES register
//   k              out  11     K register
//   n_tiles        out  16     N_TILES register
//   qz             out  8      QPARAM[7:0]
//   qlo            out  8      QPARAM[15:8]
//   qhi            out  8      QPARAM[23:16]
//   busy           in   1      from layer_fsm; STATUS.BUSY
//   fsm_state      in   8      from layer_fsm; STATUS[15:8]
//   done_set       in   1      pulse; sets STATUS.DONE
//   err_set        in   1      pulse; sets STATUS.ERROR
//   in_valid       in   1      counts CNT_ACC
//   shift_en       in   1      counts CNT_SHIFT
//   ev_wait_wb     in   1      counts CNT_WAIT_WB
//   ev_wait_out    in   1      counts CNT_WAIT_OUT
//   ev_tile        in   1      counts CNT_TILES
//   ev_out_word    in   1      counts CNT_OUT_WORDS
//
// Behaviour
//   Register map (Contract 5):
//     0x00 CTRL      write: 0 START, 1 SOFT_RESET, 2 DEST, 3 UB_WR_RST. Reads as zero.
//     0x04 STATUS    read: 0 BUSY, 1 DONE (sticky), 2 ERROR (sticky), 15:8 fsm_state
//     0x08 M_TILES   read/write, 15:0
//     0x0C K         read/write, 10:0
//     0x10 N_TILES   read/write, 15:0
//     0x14 QPARAM    read/write: 7:0 z, 15:8 lo, 23:16 hi
//     0x18 CAPS      read: 7:0 T, 15:8 13, 23:16 10, 24 PIPE, 31:28 version = 1
//     0x20 CNT_CYCLES, 0x24 CNT_ACC, 0x28 CNT_SHIFT, 0x2C CNT_WAIT_WB,
//     0x30 CNT_WAIT_OUT, 0x34 CNT_TILES, 0x38 CNT_OUT_WORDS: read, 32 bits
//   1. Accept the write address and write data independently, in either order or together.
//      Do the write and raise bvalid once both have arrived. Hold bvalid until bready.
//   2. Accept a read address, raise rvalid with the data, hold until rready.
//   3. A CTRL write sets dest = bit 2, pulses soft_reset if bit 1, pulses ub_wr_rst if bit 3.
//   4. A CTRL write with bit 0 set while busy is high is ignored: no pulse, no change.
//   5. Otherwise, if K is 0 or above 1,024, or M_TILES or N_TILES is 0: no pulse, set ERROR.
//      Do not check M_TILES * K; that needs a multiplier. The FSM flags overflow at run time.
//   6. Otherwise pulse start, and clear DONE, ERROR and all seven counters.
//   7. done_set sets DONE; err_set sets ERROR. Both stay set until the next legal START.
//   8. CNT_CYCLES adds one per cycle with busy high. Each other counter adds one per cycle
//      its enable is high. Counters are 32 bits and wrap.
//   9. Read-only registers ignore writes. Reserved bits and unused offsets read as zero.
//   10. CAPS takes T and PIPE from mxu_pkg.
//
// Timing
//   Single-beat transfers only. Every response is OKAY.
//   start, soft_reset and ub_wr_rst are exactly one cycle wide.
//   m_tiles, k and n_tiles must not change while busy; the driver never writes them then.
//   Reset (aresetn low): every register, counter and status bit is zero; no response
//   pending. rst from accel_top does not reach this block, so a soft reset keeps the
//   configuration.
//
// Resource target
//   No DSP, no block RAM.
//
// Done when
//   tb/ctrl/regfile/tb_regfile.sv prints PASS.
//
// Spec
//   docs/contracts.md, Contract 5. docs/architecture.md, section 6.2.
//   docs/verification.md, section 6.9.

module regfile (
  input  logic        clk,
  input  logic        aresetn,
  input  logic [7:0]  s_axi_awaddr,
  input  logic        s_axi_awvalid,
  output logic        s_axi_awready,
  input  logic [31:0] s_axi_wdata,
  input  logic [3:0]  s_axi_wstrb,
  input  logic        s_axi_wvalid,
  output logic        s_axi_wready,
  output logic [1:0]  s_axi_bresp,
  output logic        s_axi_bvalid,
  input  logic        s_axi_bready,
  input  logic [7:0]  s_axi_araddr,
  input  logic        s_axi_arvalid,
  output logic        s_axi_arready,
  output logic [31:0] s_axi_rdata,
  output logic [1:0]  s_axi_rresp,
  output logic        s_axi_rvalid,
  input  logic        s_axi_rready,
  output logic        start,
  output logic        soft_reset,
  output logic        dest,
  output logic        ub_wr_rst,
  output logic [15:0] m_tiles,
  output logic [10:0] k,
  output logic [15:0] n_tiles,
  output logic [7:0]  qz,
  output logic [7:0]  qlo,
  output logic [7:0]  qhi,
  input  logic        busy,
  input  logic [7:0]  fsm_state,
  input  logic        done_set,
  input  logic        err_set,
  input  logic        in_valid,
  input  logic        shift_en,
  input  logic        ev_wait_wb,
  input  logic        ev_wait_out,
  input  logic        ev_tile,
  input  logic        ev_out_word
);

endmodule
