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

  logic [64:0] expected[$];
  logic [64:0] head_word;
  int accepted = 0, received = 0;
  always @(posedge clk) begin
    if (rst) expected.delete();
    else begin
      check("event", vec_t'(ev_out_word), vec_t'(m_axis_tvalid && m_axis_tready));
      check("last_sent", vec_t'(last_sent), vec_t'(m_axis_tvalid && m_axis_tready && m_axis_tlast));
      if (m_axis_tvalid) check_known("output", vec_t'({m_axis_tlast,m_axis_tdata}), 65);
      if (m_axis_tvalid && m_axis_tready) begin
        if (expected.size() == 0) $fatal(1,"unexpected FIFO output");
        head_word = expected.pop_front();
        check("fifo order", vec_t'({m_axis_tlast,m_axis_tdata}), vec_t'(head_word));
        received++;
      end
      if (ep_valid && of_ready) begin
        if (expected.size() >= 512) $fatal(1,"FIFO overflow");
        expected.push_back({ep_last,ep_word});
        accepted++;
      end
      if (expected.size() == 512) cover_hit("full");
      if (expected.size() == 0) cover_hit("empty");
      if (ep_valid && of_ready && m_axis_tvalid && m_axis_tready) cover_hit("simultaneous");
      if (ep_valid && of_ready && ep_last && expected.size() == 1) cover_hit("first_last");
    end
  end
  initial begin
    #20000000;
    $fatal(1,"FIFO watchdog");
  end
  task automatic drain();
    u_src.wait_empty();
    while (expected.size() != 0 || m_axis_tvalid) @(negedge clk);
  endtask
  task automatic reset_fifo();
    @(negedge clk);
    u_src.clear();
    rst = 1;
    repeat (3) @(negedge clk);
    rst = 0;
  endtask
  initial begin
    rst = 1;
    void'(get_seed());
    cover_declare("full");
    cover_declare("empty");
    cover_declare("simultaneous");
    cover_declare("first_last");
    cover_declare("reset");
    repeat (3) @(negedge clk);
    rst = 0;
    test_fill_and_drain();
    test_single_word();
    test_last_word();
    test_reset_midway();
    test_random();
    $display("accepted = %0d received = %0d",accepted,received);
    finish_pass();
  end

  task automatic test_fill_and_drain();
    u_sink.set_ready_pct(0);
    repeat (3) @(negedge clk);
    for (int i=0;i<512;i++) u_src.push(64'(i),i==511);
    u_src.wait_empty();
    repeat (4) @(negedge clk);
    check("full ready",vec_t'(of_ready),0);
    check("full occupancy",vec_t'(expected.size()),512);
    u_sink.set_ready_pct(100);
    drain();
  endtask
  task automatic test_single_word();
    u_src.push(64'h123456789abcdef0,1);
    drain();
  endtask
  task automatic test_last_word();
    for (int i=0;i<16;i++) u_src.push(64'(i),i==7 || i==8);
    drain();
  endtask
  task automatic test_reset_midway();
    u_sink.set_ready_pct(0);
    repeat (3) @(negedge clk);
    for (int i=0;i<100;i++) u_src.push(64'(i),0);
    repeat (20) @(negedge clk);
    reset_fifo();
    check("reset valid",vec_t'(m_axis_tvalid),0);
    cover_hit("reset");
    u_sink.set_ready_pct(100);
    test_single_word();
  endtask
  task automatic test_random();
    u_src.set_gap_pct(30);
    u_sink.set_ready_pct(40);
    for (int i=0;i<100000;i++)
      u_src.push({$urandom(),$urandom()},$urandom_range(0,15)==0);
    drain();
  endtask
endmodule
