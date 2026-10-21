// tb_epilogue: unit bench for epilogue.
//
// DUT          rtl/ctrl/epilogue/epilogue.sv
// Stimulus     a source presents entries on rb_valid/rb_row/rb_m0/rb_sh/rb_last_o and
//              advances on rb_pop; a sink applies random of_ready.
// Reference    (a) a function in the bench implementing Contract 1 with 64-bit integers:
//              x = clamp(sum, -2**24, 2**24-1); r = (x*m0 + (1 << (sh-1))) >>> sh;
//              y = clamp(qz + r, qlo, qhi); byte j of the word = y for sum j.
//              (b) the epi_* vector sets: epi_<name>_in.hex (70 digits,
//              {1'b0, last, s[5:0], M0[15:0], row[255:0]}), epi_<name>_out.hex (16 digits),
//              epi_<name>_cfg.hex (3 lines: z, lo, hi).
// Assertions   one output word per popped entry. ep_valid and ep_word hold until of_ready.
//              rb_pop only when rb_valid. No X on ep_word when ep_valid.
// Must hit     saturation high and low; clamp low, high and not at all; sh = 1 and 47;
//              M0 = 0; an exact tie; a negative result; a stall on each of the 4 steps; an
//              entry with last = 1.
// Done when    the in-bench random test passes on three seeds first; then every epi_* line
//              matches and the rate test passes.
// Spec         docs/verification.md, section 6.7. docs/architecture.md, section 6.10.
//
// Each test in the plan is a task below; the initial block runs them in order.
// Bench rules: docs/verification.md, section 2.

module tb_epilogue;
  import tb_pkg::*;

  logic              clk = 1'b0;
  logic              rst;
  logic              rb_valid;
  logic [255:0]      rb_row;
  logic [15:0]       rb_m0;
  logic [5:0]        rb_sh;
  logic              rb_last_o;
  logic              rb_pop;
  logic signed [7:0] qz;
  logic signed [7:0] qlo;
  logic signed [7:0] qhi;
  logic              ep_valid;
  logic [63:0]       ep_word;
  logic              ep_last;
  logic              of_ready;

  always #5 clk = ~clk;

  epilogue dut (.*);

  initial begin
    $display("SKIP: not implemented"); $finish;
    void'(get_seed());
    test_vectors();
    test_lane_order();
    test_sat_edges();
    test_ties();
    test_lo_equals_hi();
    test_rate();
    test_last();
    test_reset_midway();
    test_random();
    finish_pass();
  end

  // 1. epi_corners and epi_random from vectors/; fails if any output word differs from epi_<name>_out.hex.
  task automatic test_vectors();
  endtask

  // 2. One nonzero sum in each of the 8 positions; fails unless only that byte differs from the all-zero result.
  task automatic test_lane_order();
  endtask

  // 3. Sums 2**24-1, 2**24, -2**24, -2**24-1; fails on any mismatch with the in-bench reference.
  task automatic test_sat_edges();
  endtask

  // 4. Values exactly half-way between two outputs, positive and negative; fails unless both round toward +infinity.
  task automatic test_ties();
  endtask

  // 5. qlo = qhi; fails unless every byte equals that value.
  task automatic test_lo_equals_hi();
  endtask

  // 6. 8 entries offered at once, of_ready high; fails unless 8 words leave within 32 cycles plus the pipeline depth.
  task automatic test_rate();
  endtask

  // 7. One entry with last among others; fails unless ep_last is high on exactly that entry's word.
  task automatic test_last();
  endtask

  // Rule 5. rst with entries in the pipeline, then clean entries; fails unless only the clean entries' words come out, correct.
  task automatic test_reset_midway();
  endtask

  // Random. 100,000 entries, half uniform INT32 and half within +-300 of +-2**24, random M0/sh/qz/qlo/qhi, random stalls; fails on mismatch.
  task automatic test_random();
  endtask

endmodule
