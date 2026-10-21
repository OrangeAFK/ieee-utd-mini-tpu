// tb_res_buf: unit bench for res_buf.
//
// DUT          rtl/ctrl/res_buf/res_buf.sv, DEPTH = 16
// Stimulus     a burst generator sends 8-row bursts (res_valid high 8 cycles) with
//              rb_discard and rb_last, only while can_take_tile is high; a consumer pops the
//              head at random.
// Reference    a SystemVerilog queue of {last, sh, m0, row}: on each non-discarded row c,
//              push {rb_last & (c == 7), cur_sh[c], cur_m0[c], res_row}.
// Assertions   no push when full and no pop when empty. The fill count never passes 16.
//              can_take_tile equals "at least 8 free".
// Must hit     full at 16; empty; a push and a pop in the same cycle; a discarded burst
//              followed at once by a real one; a burst with rb_last.
// Done when    every task below passes; synthesized alone, no block RAM.
// Spec         docs/verification.md, section 6.6. docs/architecture.md, section 6.9.
//
// Each test in the plan is a task below; the initial block runs them in order.
// Bench rules: docs/verification.md, section 2.

module tb_res_buf;
  import tb_pkg::*;

  logic             clk = 1'b0;
  logic             rst;
  logic             res_valid;
  logic [255:0]     res_row;
  logic             rb_discard;
  logic             rb_last;
  logic [7:0][15:0] cur_m0;
  logic [7:0][5:0]  cur_sh;
  logic             can_take_tile;
  logic             rb_valid;
  logic [255:0]     rb_row;
  logic [15:0]      rb_m0;
  logic [5:0]       rb_sh;
  logic             rb_last_o;
  logic             rb_pop;

  always #5 clk = ~clk;

  res_buf #(.DEPTH(16)) dut (.*);

  initial begin
    $display("SKIP: not implemented"); $finish;
    void'(get_seed());
    test_discard_only();
    test_two_bursts_full();
    test_scale_per_channel();
    test_scale_captured();
    test_last_on_eighth_row();
    test_reset_midway();
    test_random();
    finish_pass();
  end

  // 1. One discarded burst; fails unless rb_valid stays low and the buffer is empty after it.
  task automatic test_discard_only();
  endtask

  // 2. Two bursts back to back, no pops; fails unless count reaches 16 and can_take_tile drops after row 0 of the second.
  task automatic test_two_bursts_full();
  endtask

  // 3. 8 distinct cur_m0 and cur_sh values; fails unless row c comes out with cur_m0[c] and cur_sh[c].
  task automatic test_scale_per_channel();
  endtask

  // 4. Change cur_m0 and cur_sh the cycle after a burst ends; fails if any stored row shows the new values.
  task automatic test_scale_captured();
  endtask

  // 5. A burst with rb_last high; fails unless only its eighth row has rb_last_o set.
  task automatic test_last_on_eighth_row();
  endtask

  // Rule 5. rst with entries stored, then a clean burst; fails unless only the clean burst's rows come out.
  task automatic test_reset_midway();
  endtask

  // Random. 10,000 bursts when can_take_tile, random pop stalls, 10% discards; fails on any mismatch with the queue.
  task automatic test_random();
  endtask

endmodule
