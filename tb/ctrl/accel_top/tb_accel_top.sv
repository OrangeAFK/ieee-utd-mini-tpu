// tb_accel_top: integration bench for accel_top.
//
// DUT          rtl/ctrl/accel_top/accel_top.sv with the real mxu inside
// Neighbours   axil_master stands in for the driver; axis_src for DMA MM2S on s_axis;
//              axis_sink for DMA S2MM on m_axis. axis_check watches both streams.
//              mxu_check watches the mxu inside the DUT: bind it to dut.u_mxu once
//              accel_top instantiates the array under that name.
// Reference    layer vector sets from vectors/: layer_<name>_a.hex, _w.hex, _o.hex (16
//              digits per word) and _cfg.hex (6 lines: M_TILES, K, N_TILES, z, lo, hi).
//              The scoreboard compares o_img word for word and checks where tlast fell.
// run_layer    follows the twelve steps of docs/architecture.md, section 8: UB_WR_RST with
//              DEST = 0, send a_img, write shape and QPARAM, DEST = 1, queue w_img, START,
//              collect m_axis until tlast, poll STATUS.DONE, read the counters.
// Counters     at the end of every run: CNT_TILES = M_T*N_T, CNT_ACC = M_T*N_T*K,
//              CNT_SHIFT = 8*(M_T*N_T + 1), CNT_OUT_WORDS = M_T*N.
// Assertions   the checkers. tlast exactly once per layer. DONE only after the tlast word was
//              accepted. No X on m_axis when valid.
// Must hit     CNT_WAIT_WB > 0 in some run; CNT_WAIT_OUT > 0 in some run; a block swap while
//              the weight stream is stalled; a layer with K < 10; N_T = 1; M_T = 1.
// Done when    every task below passes with the real mxu, the counter identities hold in
//              every run, and the synthesis report is committed.
// Spec         docs/verification.md, section 6.11. docs/architecture.md, sections 5 and 8.
//
// Each test in the plan is a task below; the initial block runs them in order.
// Bench rules: docs/verification.md, section 2.

module tb_accel_top;
  import tb_pkg::*;

  logic        clk = 1'b0;
  logic        aresetn;
  logic        rst;
  logic [7:0]  s_axi_awaddr;
  logic        s_axi_awvalid;
  logic        s_axi_awready;
  logic [31:0] s_axi_wdata;
  logic [3:0]  s_axi_wstrb;
  logic        s_axi_wvalid;
  logic        s_axi_wready;
  logic [1:0]  s_axi_bresp;
  logic        s_axi_bvalid;
  logic        s_axi_bready;
  logic [7:0]  s_axi_araddr;
  logic        s_axi_arvalid;
  logic        s_axi_arready;
  logic [31:0] s_axi_rdata;
  logic [1:0]  s_axi_rresp;
  logic        s_axi_rvalid;
  logic        s_axi_rready;
  logic [63:0] s_axis_tdata;
  logic        s_axis_tvalid;
  logic        s_axis_tready;
  logic        s_axis_tlast;
  logic [7:0]  s_axis_tkeep;
  logic [63:0] m_axis_tdata;
  logic        m_axis_tvalid;
  logic        m_axis_tready;
  logic        m_axis_tlast;
  logic [7:0]  m_axis_tkeep;

  always #5 clk = ~clk;
  assign rst          = ~aresetn;
  assign s_axis_tkeep = 8'hFF;

  accel_top dut (.*);

  axil_master #(.AW(8)) u_axil (
    .clk, .rst,
    .m_axi_awaddr(s_axi_awaddr), .m_axi_awvalid(s_axi_awvalid), .m_axi_awready(s_axi_awready),
    .m_axi_wdata(s_axi_wdata), .m_axi_wstrb(s_axi_wstrb), .m_axi_wvalid(s_axi_wvalid),
    .m_axi_wready(s_axi_wready), .m_axi_bresp(s_axi_bresp), .m_axi_bvalid(s_axi_bvalid),
    .m_axi_bready(s_axi_bready), .m_axi_araddr(s_axi_araddr), .m_axi_arvalid(s_axi_arvalid),
    .m_axi_arready(s_axi_arready), .m_axi_rdata(s_axi_rdata), .m_axi_rresp(s_axi_rresp),
    .m_axi_rvalid(s_axi_rvalid), .m_axi_rready(s_axi_rready)
  );

  axis_src #(.W(64)) u_src (
    .clk, .rst, .tdata(s_axis_tdata), .tvalid(s_axis_tvalid), .tready(s_axis_tready),
    .tlast(s_axis_tlast)
  );

  axis_sink #(.W(64)) u_sink (
    .clk, .rst, .tdata(m_axis_tdata), .tvalid(m_axis_tvalid), .tready(m_axis_tready),
    .tlast(m_axis_tlast)
  );

  axis_check #(.W(64), .NAME("s_axis")) u_chk_s (
    .clk, .rst, .enable(1'b1), .tdata(s_axis_tdata), .tvalid(s_axis_tvalid),
    .tready(s_axis_tready), .tlast(s_axis_tlast)
  );

  axis_check #(.W(64), .NAME("m_axis")) u_chk_m (
    .clk, .rst, .enable(1'b1), .tdata(m_axis_tdata), .tvalid(m_axis_tvalid),
    .tready(m_axis_tready), .tlast(m_axis_tlast)
  );

  initial begin
    $display("SKIP: not implemented"); $finish;
    void'(get_seed());
    test_named_layers();
    test_back_to_back();
    test_soft_reset_midlayer();
    test_weight_stream_timing();
    test_sink_stall();
    test_illegal_shape();
    test_random();
    finish_pass();
  end

  // Helper, not a test. Runs vector set `name` under stall profile 0 none, 1 light, 2 heavy,
  // compares o_img and tlast position, checks DONE and the four counter identities.
  task automatic run_layer(input string name, input int profile);
  endtask

  // 1. layer_single, layer_mid, layer_demo1; fails on any output word, tlast position, DONE or counter identity mismatch.
  task automatic test_named_layers();
  endtask

  // 2. Two different layers back to back, no reset; fails unless the second is still bit-exact.
  task automatic test_back_to_back();
  endtask

  // 3. CTRL.SOFT_RESET in the middle of a layer, then a clean layer; fails unless the clean layer is bit-exact.
  task automatic test_soft_reset_midlayer();
  endtask

  // 4. Weight stream queued before START, then offered 1,000 cycles after START; fails unless both runs are bit-exact.
  task automatic test_weight_stream_timing();
  endtask

  // 5. Sink stalled 5,000 cycles mid-layer; fails unless the run resumes and finishes bit-exact.
  task automatic test_sink_stall();
  endtask

  // 6. An illegal shape; fails unless ERROR is set, no word moves on either stream, and the next legal layer is bit-exact.
  task automatic test_illegal_shape();
  endtask

  // Random. layer_rand_00 to _09 under all three stall profiles (all 50 locally); fails on any mismatch.
  task automatic test_random();
  endtask

endmodule
