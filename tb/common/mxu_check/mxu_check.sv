// mxu_check: Contract 4 checker.
// Watches the ports of the mxu and stops the simulation the first time either side breaks
// the timing rules. Used on the array itself, on the FSM that drives it, and at top level.
//
// Ports
//   name       dir    width  meaning
//   clk        in     1      bench clock
//   rst        in     1      synchronous, active high; no checks while high, history cleared
//   enable     in     1      checks run only while high; tb_mxu test 7 turns it off
//   in_valid   in     1      mxu input
//   shift_en   in     1      mxu input
//   res_valid  in     1      mxu output
//   res_row    in     32*T   mxu output
//   T          param  int    mxu_pkg::T
//   FLUSH_LAT  param  int    mxu_pkg::FLUSH_LAT
//   SHIFT_LAT  param  int    mxu_pkg::SHIFT_LAT
//
// Behaviour
//   On every clock edge with rst low and enable high, check:
//   1. shift_en is high for exactly T consecutive cycles per burst.
//   2. in_valid is never high while shift_en is high.
//   3. The first cycle of a burst comes at least FLUSH_LAT cycles after the last in_valid:
//      if in_valid was last high in cycle t, shift_en may first rise in cycle t + FLUSH_LAT.
//   4. res_valid is high for exactly T cycles, starting SHIFT_LAT cycles after shift_en
//      rises.
//   5. res_row holds no X or Z while res_valid is high.
//   On any violation: print the rule number, the time and the counts; call $fatal.
//   Instantiate it next to the mxu with the same signals, or bind it into the mxu.
//
// Timing
//   Count cycles with plain counters in an always block; no concurrent assertions, so
//   both Verilator and the Vivado simulator run it.
//   Before the first in_valid after reset, rule 3 is satisfied.
//
// Resource target
//   simulation only
//
// Done when
//   tb/mxu/mxu/tb_mxu.sv passes with it watching the array, and test 7 shows it fails when
//   the gap before a shift is one cycle short.
//
// Spec
//   docs/contracts.md, Contract 4. docs/verification.md, section 4.

module mxu_check #(
  parameter int T         = mxu_pkg::T,
  parameter int FLUSH_LAT = mxu_pkg::FLUSH_LAT,
  parameter int SHIFT_LAT = mxu_pkg::SHIFT_LAT
) (
  input  logic            clk,
  input  logic            rst,
  input  logic            enable,
  input  logic            in_valid,
  input  logic            shift_en,
  input  logic            res_valid,
  input  logic [32*T-1:0] res_row
);

endmodule
