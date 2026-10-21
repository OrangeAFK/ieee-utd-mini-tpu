// tb_wload: unit bench for wload, run together with wb_pair.
//
// DUT          rtl/ctrl/wload/wload.sv and rtl/ctrl/wb_pair/wb_pair.sv, AW = 10, wired as
//              in accel_top (wb_we/wb_waddr/wb_wdata/active into wb_pair)
// Stimulus     axis_src plays a w_img (docs/contracts.md, Contract 2) on s_valid/s_data/s_ready
//              with random gaps.
// Reference    a consumer model: waits a random time after nxt_valid, pulses swap, then reads
//              the whole active half through wb_pair (RD_LAT = 2) and the CURRENT parameters,
//              and compares them with the block it expects from the image it sent.
// Assertions   s_ready low whenever nxt_valid is high. A write never targets the active half.
//              nxt_valid falls only on swap. active changes only on swap. Exactly K + 8 words
//              accepted per block. No word accepted in L_IDLE or L_HOLD.
// Must hit     every loader state; a stall inside the parameter words and inside the weight
//              words; a swap on the first possible cycle; a swap after a long wait; the final
//              block of a layer.
// Done when    every task below passes and every assertion has been seen active at least once.
// Spec         docs/verification.md, section 6.4. docs/architecture.md, sections 6.4 and 6.5.
//
// Each test in the plan is a task below; the initial block runs them in order.
// Bench rules: docs/verification.md, section 2.

module tb_wload;
  import tb_pkg::*;

  localparam int AW     = 10;
  localparam int RD_LAT = 2;

  logic             clk = 1'b0;
  logic             rst;
  logic             start;
  logic [10:0]      k;
  logic [15:0]      n_tiles;
  logic             s_valid;
  logic [63:0]      s_data;
  logic             s_ready;
  logic             s_last;
  logic             swap;
  logic             active;
  logic             nxt_valid;
  logic             wb_we;
  logic [AW-1:0]    wb_waddr;
  logic [63:0]      wb_wdata;
  logic [7:0][31:0] cur_bias;
  logic [7:0][31:0] nxt_bias;
  logic [7:0][15:0] cur_m0;
  logic [7:0][5:0]  cur_sh;
  logic [AW-1:0]    raddr;
  logic [63:0]      rdata;

  always #5 clk = ~clk;

  wload #(.AW(AW)) dut (
    .clk, .rst, .start, .k, .n_tiles, .s_valid, .s_data, .s_ready, .swap, .active,
    .nxt_valid, .wb_we, .wb_waddr, .wb_wdata, .cur_bias, .nxt_bias, .cur_m0, .cur_sh
  );

  wb_pair #(.AW(AW)) u_wb (
    .clk, .rst, .we(wb_we), .waddr(wb_waddr), .wdata(wb_wdata), .active, .raddr, .rdata
  );

  axis_src #(.W(64)) u_src (
    .clk, .rst, .tdata(s_data), .tvalid(s_valid), .tready(s_ready), .tlast(s_last)
  );

  initial begin
    $display("SKIP: not implemented"); $finish;
    void'(get_seed());
    test_k_extremes();
    test_one_block();
    test_three_blocks_fast_swap();
    test_param_fields();
    test_no_extra_words();
    test_stream_before_start();
    test_reset_midway();
    test_random();
    finish_pass();
  end

  // 1. Layers with K = 1 and K = 1,024 (fills a half exactly); fails if any weight or parameter reads back wrong.
  task automatic test_k_extremes();
  endtask

  // 2. N_T = 1: one block, one swap; fails unless the block reads back right and the loader returns to L_IDLE (s_ready low).
  task automatic test_one_block();
  endtask

  // 3. N_T = 3, swap as soon as each block is ready; fails if any block reads back wrong or CURRENT and NEXT cross.
  task automatic test_three_blocks_fast_swap();
  endtask

  // 4. Parameter words with every field at min and max, including a negative bias; fails if any cur_* or nxt_bias field differs.
  task automatic test_param_fields();
  endtask

  // 5. Extra words queued after the final block; fails if s_ready rises or any extra word is accepted.
  task automatic test_no_extra_words();
  endtask

  // 6. Stream offered before start; fails if any word is accepted before start.
  task automatic test_stream_before_start();
  endtask

  // Rule 5. rst in the middle of a weight block, then a clean layer; fails unless the clean layer reads back exactly.
  task automatic test_reset_midway();
  endtask

  // Random. 200 layers, K 1..1,024, N_T 1..8, random tvalid gaps and swap delay; fails on any readback mismatch or assertion.
  task automatic test_random();
  endtask

endmodule
