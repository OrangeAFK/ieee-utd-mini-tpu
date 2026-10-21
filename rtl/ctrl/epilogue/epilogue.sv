// epilogue: requantization.
// Turns the 8 INT32 sums of one res_buf entry into 8 INT8 outputs and packs them into one
// 64-bit output word for out_fifo.
//
// Ports
//   name       dir  width      meaning
//   clk        in   1          the one clock
//   rst        in   1          synchronous, active high; empties the pipeline
//   rb_valid   in   1          res_buf has a head entry
//   rb_row     in   256        head entry sums; sum j = bits [32j+31:32j], signed
//   rb_m0      in   16         M0, unsigned
//   rb_sh      in   6          s, 1 to 47
//   rb_last_o  in   1          head entry is the layer's last row
//   rb_pop     out  1          pulse when the entry's last pair has been taken
//   qz         in   8 signed   output zero point z
//   qlo        in   8 signed   clamp low bound
//   qhi        in   8 signed   clamp high bound
//   ep_valid   out  1          ep_word and ep_last are valid
//   ep_word    out  64         byte j = y for sum j
//   ep_last    out  1          copy of the entry's last bit
//   of_ready   in   1          out_fifo can take a word
//
// Behaviour
//   Two lanes, each with one DSP48E1. Each entry takes 4 steps; on step t (0 to 3) lane 0
//   takes sum j = 2t and lane 1 takes j = 2t + 1. Per lane, per sum:
//   1. x = sat25(sum): clamp the INT32 to [-2**24, 2**24 - 1]. x fits 25 bits signed.
//   2. In the DSP: P = x * m0 + (1 << (sh - 1)). A = x, B = {2'b00, m0} (M0 is unsigned),
//      C = the rounding constant. P fits 48 bits.
//   3. r = P >>> sh, an arithmetic shift, so it floors and ties round toward +infinity.
//   4. y = clamp(qz + r, qlo, qhi), compared at full width, then truncated to 8 bits.
//      qz + r can be far outside 8 bits; never truncate before the compare.
//   5. Collect the 8 bytes; byte j of ep_word is y for sum j. Then raise ep_valid with
//      ep_last = the entry's last bit.
//   6. Pulse rb_pop for one cycle when the entry's last pair (t = 3) has been taken.
//      Never pop while rb_valid is low.
//   This is exactly Contract 1's layer() after the matrix product.
//
// Timing
//   Rate: 4 cycles per entry, 32 per tile, while of_ready stays high. Pipeline depth is
//   free; the rate is not.
//   ep_valid / of_ready is a valid/ready handshake: a word moves when both are high.
//   ep_valid, ep_word and ep_last hold until it moves.
//   The whole pipeline stalls while a word is waiting and of_ready is low; nothing is lost
//   or duplicated.
//   Reset: no word valid, step counter 0.
//
// Resource target
//   2 DSP48E1, no multiplier built from LUTs, no block RAM.
//
// Done when
//   tb/ctrl/epilogue/tb_epilogue.sv prints PASS: first against its in-bench reference,
//   then also on every line of the epi_* vector sets, plus the rate test.
//
// Spec
//   docs/contracts.md, Contract 1. docs/architecture.md, section 6.10.
//   docs/verification.md, section 6.7.

module epilogue (
  input  logic              clk,
  input  logic              rst,
  input  logic              rb_valid,
  input  logic [255:0]      rb_row,
  input  logic [15:0]       rb_m0,
  input  logic [5:0]        rb_sh,
  input  logic              rb_last_o,
  output logic              rb_pop,
  input  logic signed [7:0] qz,
  input  logic signed [7:0] qlo,
  input  logic signed [7:0] qhi,
  output logic              ep_valid,
  output logic [63:0]       ep_word,
  output logic              ep_last,
  input  logic              of_ready
);

endmodule
