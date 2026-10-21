// tb_out_fifo: unit bench for out_fifo.
//
// DUT          rtl/ctrl/out_fifo/out_fifo.sv, DEPTH = 512
// Reference    a SystemVerilog queue of {last, word}, pushed when ep_valid & of_ready
// Neighbours   axis_src drives the ep_* side (its tready is of_ready); axis_sink takes
//              m_axis with random tready; axis_check watches m_axis.
// Assertions   everything in axis_check. No write when full. last_sent high for one cycle,
//              exactly when the tlast word is accepted. ev_out_word == tvalid & tready.
// Must hit     full at 512; empty; write and read in the same cycle; last on the first word
//              after empty.
// Done when    every task below passes and synthesized alone out_fifo shows 1 RAMB36E1.
// Spec         docs/verification.md, section 6.8. docs/architecture.md, section 6.11.
//
// Each test in the plan is a task below; the initial block runs them in order.
// Bench rules: docs/verification.md, section 2.

module tb_out_fifo;
  import tb_pkg::*;

  logic        clk = 1'b0;
  logic        rst;
  logic        ep_valid;
  logic [63:0] ep_word;
  logic        ep_last;
  logic        of_ready;
  logic [63:0] m_axis_tdata;
  logic        m_axis_tlast;
  logic        m_axis_tvalid;
  logic        m_axis_tready;
  logic        last_sent;
  logic        ev_out_word;

  always #5 clk = ~clk;

  out_fifo #(.DEPTH(512)) dut (.*);

  axis_src #(.W(64)) u_src (
    .clk(clk), .rst(rst),
    .tdata(ep_word), .tvalid(ep_valid), .tready(of_ready), .tlast(ep_last)
  );

  axis_sink #(.W(64)) u_sink (
    .clk(clk), .rst(rst),
    .tdata(m_axis_tdata), .tvalid(m_axis_tvalid), .tready(m_axis_tready), .tlast(m_axis_tlast)
  );

  axis_check #(.W(64), .NAME("m_axis")) u_chk (
    .clk(clk), .rst(rst), .enable(1'b1),
    .tdata(m_axis_tdata), .tvalid(m_axis_tvalid), .tready(m_axis_tready), .tlast(m_axis_tlast)
  );

  initial begin
    $display("SKIP: not implemented"); $finish;
    void'(get_seed());
    test_fill_and_drain();
    test_single_word();
    test_last_word();
    test_reset_midway();
    test_random();
    finish_pass();
  end

  // 1. Sink stalled, write until of_ready drops, then drain; fails unless exactly 512 words enter and all leave in order.
  task automatic test_fill_and_drain();
  endtask

  // 2. One word into an empty FIFO; fails if m_axis_tvalid never rises without an extra request or the word differs.
  task automatic test_single_word();
  endtask

  // 3. A word with last among others; fails unless tlast rises with that word only and last_sent pulses exactly once.
  task automatic test_last_word();
  endtask

  // Rule 5. rst with words stored, then a clean run; fails unless m_axis_tvalid drops and only post-reset words appear.
  task automatic test_reset_midway();
  endtask

  // Random. 100,000 words, random stalls both sides, last on random words; fails on any order, data or last mismatch.
  task automatic test_random();
  endtask

endmodule
