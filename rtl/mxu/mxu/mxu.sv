// mxu: the T x T output-stationary array and its two skew networks.
// Takes one activation word and one weight word per cycle, accumulates T*T dot products in
// place, and on a shift hands the sums out one channel per cycle while taking in the next
// tile's biases.
//
// Ports (widths for T = 8; at T = 4 the words are 32 bits and res_row is 128)
//   name       dir  width   meaning
//   clk        in   1       the one clock
//   rst        in   1       synchronous, active high; zeroes every sum
//   in_valid   in   1       a_word and w_word are word k of the current tile
//   a_word     in   8*T     byte j = activation for tile row j; treated as zero when in_valid is low
//   w_word     in   8*T     byte c = weight for channel c
//   shift_en   in   1       high for exactly T consecutive cycles; drains the sums, loads the next bias
//   bias_in    in   32      on the c-th cycle of shift_en: bias for channel c of the next tile
//   res_valid  out  1       high for exactly T cycles per shift burst
//   res_row    out  32*T    on the c-th valid cycle, bits [32j+31:32j] = INT32 sum for row j, channel c
//   T          param int    array side, 8 in hardware, 4 in fast simulation
//   PIPE       param bit    passed to every pe; 1 = systolic with skew, 0 = broadcast with no skew
//
// Behaviour
//   PE(r, j) is the PE in row r, column j; r and j run 0 to T-1. Build T*T pe instances.
//   1. Activations run down columns. Byte j of a_word, forced to zero when in_valid is low,
//      is delayed j*PIPE cycles and drives a_in of PE(0, j). a_out of PE(r, j) drives a_in
//      of PE(r+1, j).
//   2. Weights run along rows in reversed channel order. Row r carries channel c = T-1-r.
//      Byte c of w_word is delayed r*PIPE cycles, that is (T-1-c)*PIPE, and drives w_in of
//      PE(r, 0). w_out of PE(r, j) drives w_in of PE(r, j+1).
//   3. Sums chain down columns. c_in of PE(0, j) is bias_in sign-extended to 48 bits, the
//      same for every column. c_in of PE(r, j) is p of PE(r-1, j).
//   4. shift of every PE is shift_en. res_valid is shift_en. Bits [32j+31:32j] of res_row
//      are p[31:0] of PE(T-1, j).
//   5. Gate the activations with in_valid, not the weights. A zero activation makes the
//      product zero whatever the weight is.
//   The skew networks are generate blocks inside this module, not separate files.
//
//   Function: after a shift burst that loaded bias8, and K words with in_valid, the next
//   burst returns res[c][j] = bias8[c] + sum over k of a[k][j] * w[k][c], channel 0 first.
//
// Timing (T = 8, PIPE = 1; for a word accepted at cycle t)
//   Its bytes meet on a_in and w_in of PE(r, j) at t + r + j.
//   The product is inside p of PE(r, j) from t + r + j + 3.
//   PE(7, 7) has it from t + 17 = FLUSH_LAT. With PIPE = 0 every PE sees the word at t and
//   FLUSH_LAT is 3.
//   The controller never raises in_valid during a burst, raises shift_en no earlier than
//   FLUSH_LAT cycles after the last in_valid, and may resume in_valid the cycle after
//   shift_en falls. res_valid starts SHIFT_LAT = 0 cycles after shift_en rises.
//   Gaps in in_valid inside a tile are legal; they only add zeros. No stall input.
//   Reset: every sum is zero; the next shift burst returns zeros.
//
// Resource target
//   64 DSP48E1 at T = 8, 0 CARRY4 inside any pe, no block RAM, timing met at 8.000 ns.
//   Report LUTs, flip-flops and worst slack for PIPE = 1 and PIPE = 0, and whether the
//   P chain used the dedicated DSP cascade.
//
// Done when
//   tb/mxu/mxu/tb_mxu.sv prints PASS for T = 4 and 8 crossed with PIPE = 0 and 1, and
//   FLUSH_LAT and SHIFT_LAT in mxu_pkg equal what the bench measured.
//
// Spec
//   docs/contracts.md, Contract 4. docs/architecture.md, section 6.7.
//   docs/verification.md, section 6.2.

module mxu #(
  parameter int T    = mxu_pkg::T,
  parameter bit PIPE = mxu_pkg::PIPE
) (
  input  logic              clk,
  input  logic              rst,
  input  logic              in_valid,
  input  logic [8*T-1:0]    a_word,
  input  logic [8*T-1:0]    w_word,
  input  logic              shift_en,
  input  logic [31:0]       bias_in,
  output logic              res_valid,
  output logic [32*T-1:0]   res_row
);

endmodule
