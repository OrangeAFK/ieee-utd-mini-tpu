// mxu_pkg: constants the array exports to everything around it.
// layer_fsm, regfile and the benches read these instead of hard-coding numbers.
//
// Ports
//   none. It is a package; it exports these constants:
//   name       type  value  meaning
//   T          int   8      array side; 4 in fast simulation
//   PIPE       bit   1      1: operands pass PE to PE through registers, inputs skewed. 0: broadcast
//   FLUSH_LAT  int   17     cycles after the last in_valid before shift_en may rise; 2*(T-1)*PIPE + 3
//   SHIFT_LAT  int   0      cycles from shift_en rising to the first res_valid
//
// Behaviour
//   1. Constants only. No types, functions or logic.
//   2. If the array gains or loses a pipeline stage, FLUSH_LAT changes here. Nothing else
//      in the design notices otherwise.
//
// Timing
//   FLUSH_LAT and SHIFT_LAT are Contract 4, timing rules 2 and 4.
//
// Resource target
//   none
//
// Done when
//   tb/mxu/mxu/tb_mxu.sv test 7 measures FLUSH_LAT and SHIFT_LAT equal to the values here,
//   for T = 8 and PIPE = 1.
//
// Spec
//   docs/contracts.md, Contract 4. docs/architecture.md, section 3.

package mxu_pkg;

  // Reference values for T = 8, PIPE = 1. They are replaced when the real array lands,
  // with the values its bench measures.
  localparam int T         = 8;
  localparam bit PIPE      = 1'b1;
  localparam int FLUSH_LAT = 17;
  localparam int SHIFT_LAT = 0;

endpackage
