// axis_check: AXI4-Stream protocol checker.
// Watches one stream and stops the simulation the first time the source breaks the
// valid/ready rules.
//
// Ports
//   name    dir    width   meaning
//   clk     in     1       bench clock
//   rst     in     1       synchronous, active high; no checks while high
//   enable  in     1       checks run only while high
//   tdata   in     W       stream data
//   tvalid  in     1       stream valid
//   tready  in     1       stream ready
//   tlast   in     1       stream last
//   W       param  int     64
//   NAME    param  string  printed in every message, e.g. "m_axis"
//
// Behaviour
//   On every clock edge with rst low and enable high:
//   1. If tvalid was high and tready low last cycle, tvalid must still be high.
//   2. In that same case, tdata and tlast must equal last cycle's values.
//   3. While tvalid is high, tdata and tlast hold no X or Z.
//   On any violation: print NAME, the rule number, the time and the values; call $fatal.
//   Keep the checks as immediate assertions or plain if statements in an always block, so
//   both Verilator and the Vivado simulator run them.
//
// Timing
//   Samples on the rising edge; compares with the values sampled one edge earlier.
//   After reset, the first cycle has no previous value and rules 1 and 2 are skipped.
//
// Resource target
//   simulation only
//
// Done when
//   tb/ctrl/out_fifo/tb_out_fifo.sv passes with this checker on m_axis, and a deliberate
//   violation (tvalid dropped before tready) makes it fail.
//
// Spec
//   docs/contracts.md, Contract 3. docs/verification.md, section 4.

module axis_check #(
  parameter int    W    = 64,
  parameter string NAME = "axis"
) (
  input  logic         clk,
  input  logic         rst,
  input  logic         enable,
  input  logic [W-1:0] tdata,
  input  logic         tvalid,
  input  logic         tready,
  input  logic         tlast
);

endmodule
