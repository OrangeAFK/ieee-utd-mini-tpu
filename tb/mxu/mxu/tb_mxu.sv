// tb_mxu: unit bench for mxu.
//
// DUT          rtl/mxu/mxu/mxu.sv with T and PIPE from the bench parameters; run.py runs
//              T = 4 and 8 crossed with PIPE = 0 and 1
// Reference    tile() from docs/contracts.md, Contract 1, rewritten here with 64-bit
//              integers: res[c][j] = bias8[c] + sum_k a[k][j] * w[k][c]. Plus every
//              vectors/tile_*_{a,w,bias,res}.hex set (T = 8 only).
// Driver       run_tile: plays K word pairs with programmable gaps, waits FLUSH_LAT plus
//              extra idle cycles, runs one T-cycle shift burst loading the next bias, and
//              collects the T result rows. It obeys Contract 4 exactly.
// Checker      mxu_check watches the DUT's ports (enable is turned off only in test 7).
// Must hit     a nonzero sum in every lane j and channel c; positive and negative sums; a sum
//              beyond +-2**16; back-to-back tiles at the minimum gap; a gap in in_valid inside
//              a tile; K = 1. One tb_pkg cover counter each.
// Done when    every task below passes for all four parameter sets, and FLUSH_LAT and
//              SHIFT_LAT in mxu_pkg equal what test 7 measured at T = 8, PIPE = 1.
// Spec         docs/verification.md, section 6.2. docs/contracts.md, Contract 4.
//
// Each test in the plan is a task below; the initial block runs them in order.
// Bench rules: docs/verification.md, section 2.

module tb_mxu #(
  parameter int T    = mxu_pkg::T,
  parameter bit PIPE = mxu_pkg::PIPE
);
  import tb_pkg::*;

  // mxu_pkg holds the values for T = 8, PIPE = 1; other combinations use the formula.
  localparam int FLUSH_LAT = (T == mxu_pkg::T && PIPE == mxu_pkg::PIPE)
                             ? mxu_pkg::FLUSH_LAT : 2 * (T - 1) * int'(PIPE) + 3;
  localparam int SHIFT_LAT = mxu_pkg::SHIFT_LAT;

  logic            clk = 1'b0;
  logic            rst;
  logic            in_valid;
  logic [8*T-1:0]  a_word;
  logic [8*T-1:0]  w_word;
  logic            shift_en;
  logic [31:0]     bias_in;
  logic            res_valid;
  logic [32*T-1:0] res_row;
  logic            chk_enable;

  always #5 clk = ~clk;

  mxu #(.T(T), .PIPE(PIPE)) dut (.*);

  mxu_check #(.T(T), .FLUSH_LAT(FLUSH_LAT), .SHIFT_LAT(SHIFT_LAT)) u_chk (
    .clk(clk), .rst(rst), .enable(chk_enable),
    .in_valid(in_valid), .shift_en(shift_en), .res_valid(res_valid), .res_row(res_row)
  );

  initial begin
    $display("SKIP: not implemented"); $finish;
    void'(get_seed());
    test_bias_only();
    test_one_hot();
    test_k1_k2();
    test_residue();
    test_gating();
    test_min_gaps();
    test_flush_tight();
    test_reset_midway();
    test_vectors();
    test_random();
    finish_pass();
  end

  // Driver, not a test. Plays one tile of k words with gap_pct chance of an idle cycle after
  // any word, waits FLUSH_LAT + extra cycles, shifts T cycles with next_bias, and returns the
  // T rows that leave (the sums of the tile just played).
  task automatic run_tile(input int k, input int gap_pct, input int extra);
  endtask

  // 1. Two shift bursts with no words between; fails unless the second returns the first's bias in every lane, channels in order.
  task automatic test_bias_only();
  endtask

  // 2. One-hot: a 1 in activation byte j0 and weight byte c0, all T*T pairs; fails if any sum other than res[c0][j0] = 1 is nonzero.
  task automatic test_one_hot();
  endtask

  // 3. Random tiles with K = 1 and K = 2; fails on any mismatch with the in-bench tile() model.
  task automatic test_k1_k2();
  endtask

  // 4. A tile of large values, then a bias-only tile; fails unless the second returns only its bias.
  task automatic test_residue();
  endtask

  // 5. a_word held nonzero with in_valid low through the settle phase; fails if any sum changes.
  task automatic test_gating();
  endtask

  // 6. 100 tiles, shift exactly FLUSH_LAT after the last word, next word right after the burst, new bias each; fails on any mismatch.
  task automatic test_min_gaps();
  endtask

  // 7. Checker off, gap one cycle short of FLUSH_LAT; fails unless the last PE's sum is wrong short and right at FLUSH_LAT.
  task automatic test_flush_tight();
  endtask

  // 8. rst in the middle of a tile, then a clean tile; fails unless the clean tile matches the model exactly.
  task automatic test_reset_midway();
  endtask

  // 9. Every tile_* vector set (T = 8 only); fails if any result row differs from tile_<name>_res.hex.
  task automatic test_vectors();
  endtask

  // Random. 2,000 tiles, K 1..64 plus K = 300 and 1,024, full-range INT8, 30% gaps, 0..5 idle before shift; fails on any mismatch.
  task automatic test_random();
  endtask

endmodule
