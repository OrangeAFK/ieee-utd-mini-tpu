// Independent single-outstanding AXI-Lite slave, register scoreboard and error injection.
module tb_axil_master;
  import tb_pkg::*;
  logic clk = 0, rst = 1;
  logic [7:0] m_axi_awaddr, m_axi_araddr;
  logic [31:0] m_axi_wdata, m_axi_rdata;
  logic [3:0] m_axi_wstrb;
  logic [1:0] m_axi_bresp = 0, m_axi_rresp = 0;
  logic m_axi_awvalid, m_axi_awready, m_axi_wvalid, m_axi_wready;
  logic m_axi_bvalid = 0, m_axi_bready, m_axi_arvalid, m_axi_arready;
  logic m_axi_rvalid = 0, m_axi_rready;
  bit aw_seen = 0, w_seen = 0, coupled = 0, blocked = 0, no_response = 0;
  logic [7:0] saved_addr;
  logic [31:0] saved_data, regs[64], reference_regs[64];
  logic [31:0] got, value;
  int cycles = 0, aw_first = -1, w_first = -1;
  bit aw_random = 0, w_random = 0, ar_random = 0;
  string negative;

  always #5 clk = ~clk;
  axil_master dut(.*);
  axis_check #(.W(8), .NAME("AW")) aw_check(
    .clk(clk),.rst(rst),.enable(1'b1),.tdata(m_axi_awaddr),
    .tvalid(m_axi_awvalid),.tready(m_axi_awready),.tlast(1'b0));
  axis_check #(.W(36), .NAME("W")) w_check(
    .clk(clk),.rst(rst),.enable(1'b1),.tdata({m_axi_wstrb,m_axi_wdata}),
    .tvalid(m_axi_wvalid),.tready(m_axi_wready),.tlast(1'b0));
  axis_check #(.W(8), .NAME("AR")) ar_check(
    .clk(clk),.rst(rst),.enable(1'b1),.tdata(m_axi_araddr),
    .tvalid(m_axi_arvalid),.tready(m_axi_arready),.tlast(1'b0));

  assign m_axi_awready = !rst && !blocked && !aw_seen &&
                         aw_random && (!coupled || m_axi_wvalid || w_seen);
  assign m_axi_wready = !rst && !blocked && !w_seen &&
                        w_random && (!coupled || m_axi_awvalid || aw_seen);
  assign m_axi_arready = !rst && !blocked && !m_axi_rvalid && ar_random;

  always @(negedge clk) begin
    aw_random = $urandom_range(0,3) != 0;
    w_random = $urandom_range(0,3) != 0;
    ar_random = $urandom_range(0,3) != 0;
  end

  always @(posedge clk) begin
    cycles <= cycles + 1;
    if (rst) begin
      aw_seen <= 0; w_seen <= 0;
      m_axi_bvalid <= 0; m_axi_rvalid <= 0;
      foreach (regs[i]) regs[i] <= 0;
    end else begin
      if (m_axi_awvalid && aw_first < 0) aw_first = cycles;
      if (m_axi_wvalid && w_first < 0) w_first = cycles;
      if (m_axi_awvalid && m_axi_awready) begin
        saved_addr <= m_axi_awaddr;
        aw_seen <= 1;
      end
      if (m_axi_wvalid && m_axi_wready) begin
        check("write strobe",vec_t'(m_axi_wstrb),15);
        saved_data <= m_axi_wdata;
        w_seen <= 1;
      end
      if (aw_seen && w_seen && !m_axi_bvalid && !no_response) begin
        regs[saved_addr[7:2]] <= saved_data;
        m_axi_bvalid <= 1;
      end
      if (m_axi_bvalid && !m_axi_bready) cover_hit("write_response_stall");
      if (m_axi_bvalid && m_axi_bready) begin
        m_axi_bvalid <= 0; aw_seen <= 0; w_seen <= 0;
      end
      if (m_axi_arvalid && m_axi_arready && !no_response) begin
        m_axi_rdata <= regs[m_axi_araddr[7:2]];
        m_axi_rvalid <= 1;
      end
      if (m_axi_rvalid && !m_axi_rready) cover_hit("read_response_stall");
      if (m_axi_rvalid && m_axi_rready) m_axi_rvalid <= 0;
    end
  end

  task automatic transaction(input int mode, input int idx, input logic [31:0] data);
    @(negedge clk);
    aw_first = -1; w_first = -1;
    dut.set_order(mode);
    dut.write(8'(idx << 2),data);
    if (mode == 1 && !(aw_first < w_first)) $fatal(1,"AW offer order");
    if (mode == 2 && !(w_first < aw_first)) $fatal(1,"W offer order");
    if (mode == 3 && aw_first != w_first) $fatal(1,"together offer order");
    reference_regs[idx] = data;
    dut.read(8'(idx << 2),got);
    check("register roundtrip",vec_t'(got),vec_t'(reference_regs[idx]));
    case (mode)
      0: cover_hit("random_order");
      1: cover_hit("address_first");
      2: cover_hit("data_first");
      3: cover_hit("together");
    endcase
    if (coupled) cover_hit("coupled_ready");
  endtask

  initial begin
    #20000000;
    $fatal(1,"AXI-Lite bench watchdog");
  end
  initial begin
    void'(get_seed());
    cover_declare("random_order"); cover_declare("address_first");
    cover_declare("data_first"); cover_declare("together");
    cover_declare("coupled_ready"); cover_declare("reset");
    cover_declare("write_response_stall"); cover_declare("read_response_stall");
    foreach (reference_regs[i]) reference_regs[i] = 0;
    repeat (3) @(negedge clk);
    rst = 0;
    if ($value$plusargs("negative=%s",negative)) begin
      if (negative == "bresp") begin
        m_axi_bresp = 2'b10;
        dut.write(0,32'h123);
      end else if (negative == "rresp") begin
        m_axi_rresp = 2'b10;
        dut.read(0,got);
      end else if (negative == "timeout") begin
        no_response = 1;
        dut.write(0,32'h123);
      end else if (negative == "reset") begin
        blocked = 1;
        fork
          dut.write(0,32'h123);
          begin repeat (5) @(negedge clk); rst = 1; end
        join
      end else $fatal(1,"unknown negative case");
      $fatal(1,"expected rejection did not occur");
    end
    dut.set_max_delay(0);
    for (int mode=0;mode<4;mode++) transaction(mode,mode,32'h12340000+32'(mode));
    dut.set_max_delay(8);
    coupled = 1;
    for (int mode=0;mode<4;mode++) transaction(mode,mode,32'h56780000+32'(mode));
    // Random response delays must actually hit the response-stall cover counters.
    for (int i=0;i<256;i++) begin
      coupled = (i % 2) != 0;
      value = $urandom();
      transaction(i%4,i%64,value);
    end
    @(negedge clk); rst = 1;
    repeat (3) @(negedge clk);
    check("reset AW",vec_t'(m_axi_awvalid),0);
    check("reset W",vec_t'(m_axi_wvalid),0);
    check("reset AR",vec_t'(m_axi_arvalid),0);
    check("reset BREADY",vec_t'(m_axi_bready),0);
    check("reset RREADY",vec_t'(m_axi_rready),0);
    rst = 0;
    foreach (reference_regs[i]) reference_regs[i] = 0;
    cover_hit("reset");
    for (int i=0;i<64;i++) begin
      dut.read(8'(i<<2),got);
      check("reset register",vec_t'(got),0);
    end
    transaction(3,0,32'hfeedbeef);
    finish_pass();
  end
endmodule
