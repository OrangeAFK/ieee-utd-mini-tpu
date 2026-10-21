// tb_pe: unit bench for pe.
//
// DUT          rtl/mxu/pe/pe.sv, PIPE from the bench parameter (run for 0 and 1)
// Reference    a three-stage model in the bench using 64-bit integers:
//              a_r, w_r <= inputs; m_r <= a_r * w_r; p <= rst ? 0 : shift ? c_in : p + m_r
// Assertions   p is never X after reset. With PIPE = 1, a_out equals the previous cycle's
//              a_in, and the same for w_out. With PIPE = 0 they equal the inputs.
// Must hit     all four sign quadrants of (a, w); a zero operand; accumulate then shift and
//              shift then accumulate on consecutive cycles; p negative; p beyond +-2**31.
//              One tb_pkg cover counter each.
// Done when    every task below passes for PIPE = 0 and 1 and the out-of-context report
//              (1 DSP48E1, 0 CARRY4, A/B/M/P registers on) is committed.
// Spec         docs/verification.md, section 6.1. docs/architecture.md, section 6.8.
//
// Each test in the plan is a task below; the initial block runs them in order.
// Bench rules: docs/verification.md, section 2.

module tb_pe #(
  parameter bit PIPE = mxu_pkg::PIPE
);
  import tb_pkg::*;

  logic               clk = 1'b0;
  logic               rst;
  logic               shift;
  logic signed [7:0]  a_in;
  logic signed [7:0]  w_in;
  logic signed [47:0] c_in;
  logic signed [7:0]  a_out;
  logic signed [7:0]  w_out;
  logic signed [47:0] p;

  always #5 clk = ~clk;

  pe #(.PIPE(PIPE)) dut (.*);

  initial begin
    $display("SKIP: not implemented"); $finish;
    void'(get_seed());
    test_reset();
    test_all_pairs();
    test_extreme_growth();
    test_shift_load();
    test_shift_during_traffic();
    test_pass_delay();
    test_reset_midway();
    test_random();
    finish_pass();
  end

  // 1. Reset gives p = 0 and it stays 0 with zero inputs; fails if p != 0 on any of 20 cycles.
  task automatic test_reset();
  endtask

  // 2. All 65,536 (a, w) pairs: clear p with one shift of c_in = 0, one pair then zeros; fails if p != a*w 3 cycles later.
  task automatic test_all_pairs();
  endtask

  // 3. Each of the four (-128/127, -128/127) pairs accumulated 1,000 times; fails if p differs from the model on any cycle.
  task automatic test_extreme_growth();
  endtask

  // 4. Shift in positive, negative and all-ones 48-bit c_in; fails if p != c_in one cycle after each shift cycle.
  task automatic test_shift_load();
  endtask

  // 5. Shift while products are in flight; fails if the product reaching P during the shift is kept or a later one is lost.
  task automatic test_shift_during_traffic();
  endtask

  // 6. Random a_in, w_in for 100 cycles; fails if a_out, w_out are not delayed by exactly PIPE cycles.
  task automatic test_pass_delay();
  endtask

  // Rule 5. rst in the middle of accumulation, then a clean run; fails if p != 0 after rst or the clean run mismatches the model.
  task automatic test_reset_midway();
  endtask

  // Random. 200,000 cycles, random pair every cycle, shift 1 in 16, random 48-bit c_in; fails on any p mismatch with the model.
  task automatic test_random();
  endtask

endmodule
