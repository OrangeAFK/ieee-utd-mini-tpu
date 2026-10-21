// pe: one multiply-accumulate cell of the array.
// Multiplies the two bytes passing through and adds the product to its own 48-bit sum,
// or, in shift mode, copies the sum of the cell above.
//
// Ports
//   name   dir  width       meaning
//   clk    in   1           the one clock
//   rst    in   1           synchronous, active high; zeroes p only
//   shift  in   1           0: accumulate. 1: p takes c_in
//   a_in   in   8 signed    activation, from the PE above or the column's skew output
//   w_in   in   8 signed    weight, from the PE on the left or the row's skew output
//   c_in   in   48 signed   p of the PE above; for the top row, bias_in sign-extended
//   a_out  out  8 signed    to the PE below: a_in delayed 1 cycle (PIPE = 1) or a_in itself (PIPE = 0)
//   w_out  out  8 signed    to the PE on the right, same rule
//   p      out  48 signed   the running sum
//   PIPE   param  bit       1: a_out and w_out are registered. 0: they are wires
//
// Behaviour
//   1. Every cycle: a_r <= a_in; w_r <= w_in (the DSP A and B registers).
//   2. Every cycle: m_r <= a_r * w_r, a signed 8x8 product in 16 bits (the DSP M register).
//   3. If rst: p <= 0.
//   4. Else if shift: p <= c_in.                 DSP OPMODE 0110000, Z = C.
//   5. Else: p <= p + m_r, m_r sign-extended.    DSP OPMODE 0100101, Z = P, X and Y = M.
//   6. PIPE = 1: a_out <= a_in and w_out <= w_in every cycle. PIPE = 0: assign a_out = a_in,
//      w_out = w_in.
//   7. Reset only p. The other registers flush themselves with zeros during idle cycles.
//   8. Declare every operand signed: -128 * -128 is +16,384 and needs the full 16-bit product.
//
// Timing
//   Operands on a_in and w_in in cycle t are inside p from cycle t + 3.
//   A shift in cycle t puts c_in into p at t + 1; a product reaching the P stage that cycle
//   is dropped. No handshake; no stall.
//
// Resource target
//   1 DSP48E1 with AREG = BREG = MREG = PREG = 1, ALUMODE 0000, and 0 CARRY4.
//   If Vivado builds the adder in LUTs, put (* use_dsp = "yes" *) on the module. If that
//   fails, instantiate DSP48E1 directly with the two OPMODEs above.
//
// Done when
//   tb/mxu/pe/tb_pe.sv prints PASS for PIPE = 0 and 1, and the out-of-context utilization
//   report showing 1 DSP48E1 and 0 CARRY4 is committed.
//
// Spec
//   docs/architecture.md, section 6.8. docs/verification.md, section 6.1.

module pe #(
  parameter bit PIPE = mxu_pkg::PIPE
) (
  input  logic               clk,
  input  logic               rst,
  input  logic               shift,
  input  logic signed [7:0]  a_in,
  input  logic signed [7:0]  w_in,
  input  logic signed [47:0] c_in,
  output logic signed [7:0]  a_out,
  output logic signed [7:0]  w_out,
  output logic signed [47:0] p
);

endmodule
