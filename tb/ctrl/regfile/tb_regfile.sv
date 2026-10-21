// tb_regfile: unit bench for regfile.
//
// DUT          rtl/ctrl/regfile/regfile.sv
// Stimulus     axil_master on s_axi with random delays on all five channels; simple
//              generators drive busy, fsm_state, done_set, err_set and the event inputs.
// Reference    a register model in the bench implementing docs/contracts.md, Contract 5,
//              and the rules in docs/architecture.md, section 6.2.
// Assertions   a write response only after both address and data were accepted. A read
//              response only after the address was accepted. Every response is OKAY. start,
//              soft_reset and ub_wr_rst are one cycle wide. start never rises while busy.
// Must hit     every register written and read; address before data, data before address,
//              and both together; a stalled response channel; each of the four reasons START
//              is refused.
// Done when    every task below passes; synthesized alone, no DSP and no block RAM.
// Spec         docs/verification.md, section 6.9. docs/contracts.md, Contract 5.
//
// Each test in the plan is a task below; the initial block runs them in order.
// Bench rules: docs/verification.md, section 2.

module tb_regfile;
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
  logic        start;
  logic        soft_reset;
  logic        dest;
  logic        ub_wr_rst;
  logic [15:0] m_tiles;
  logic [10:0] k;
  logic [15:0] n_tiles;
  logic [7:0]  qz;
  logic [7:0]  qlo;
  logic [7:0]  qhi;
  logic        busy;
  logic [7:0]  fsm_state;
  logic        done_set;
  logic        err_set;
  logic        in_valid;
  logic        shift_en;
  logic        ev_wait_wb;
  logic        ev_wait_out;
  logic        ev_tile;
  logic        ev_out_word;

  always #5 clk = ~clk;
  assign rst = ~aresetn;

  regfile dut (.*);

  axil_master #(.AW(8)) u_axil (
    .clk, .rst,
    .m_axi_awaddr(s_axi_awaddr), .m_axi_awvalid(s_axi_awvalid), .m_axi_awready(s_axi_awready),
    .m_axi_wdata(s_axi_wdata), .m_axi_wstrb(s_axi_wstrb), .m_axi_wvalid(s_axi_wvalid),
    .m_axi_wready(s_axi_wready), .m_axi_bresp(s_axi_bresp), .m_axi_bvalid(s_axi_bvalid),
    .m_axi_bready(s_axi_bready), .m_axi_araddr(s_axi_araddr), .m_axi_arvalid(s_axi_arvalid),
    .m_axi_arready(s_axi_arready), .m_axi_rdata(s_axi_rdata), .m_axi_rresp(s_axi_rresp),
    .m_axi_rvalid(s_axi_rvalid), .m_axi_rready(s_axi_rready)
  );

  initial begin
    $display("SKIP: not implemented"); $finish;
    void'(get_seed());
    test_reset_values();
    test_walking_ones();
    test_legal_start();
    test_illegal_start();
    test_start_while_busy();
    test_ctrl_bits();
    test_done_sticky();
    test_counters();
    test_caps();
    test_reset_midway();
    test_random();
    finish_pass();
  end

  // 1. Read every register after reset; fails unless each reads zero (CAPS reads its constants).
  task automatic test_reset_values();
  endtask

  // 2. Walking ones through every writable field, reads of reserved bits, writes to read-only registers; fails on any model mismatch.
  task automatic test_walking_ones();
  endtask

  // 3. A legal START; fails unless start pulses exactly one cycle and DONE, ERROR and all counters read zero after.
  task automatic test_legal_start();
  endtask

  // 4. START with K = 0, K = 1,025, M_TILES = 0, N_TILES = 0; fails if start pulses or ERROR stays clear in any case.
  task automatic test_illegal_start();
  endtask

  // 5. START while busy is high; fails if start pulses.
  task automatic test_start_while_busy();
  endtask

  // 6. CTRL writes with and without DEST and UB_WR_RST; fails unless dest follows bit 2 and ub_wr_rst pulses once per write with bit 3.
  task automatic test_ctrl_bits();
  endtask

  // 7. Pulse done_set; fails unless DONE reads 1 across later reads and clears only on the next legal START.
  task automatic test_done_sticky();
  endtask

  // 8. Hold each counter's enable high N cycles (busy for CNT_CYCLES); fails unless the counter reads N.
  task automatic test_counters();
  endtask

  // 9. Read CAPS; fails unless it equals {4'd1, 3'b0, PIPE, 8'd10, 8'd13, T} from mxu_pkg.
  task automatic test_caps();
  endtask

  // Rule 5. aresetn low in the middle of a write, then a clean write and read; fails unless the clean pair matches the model.
  task automatic test_reset_midway();
  endtask

  // Random. 20,000 reads and writes to random offsets, random delays on all channels; fails on any mismatch with the model.
  task automatic test_random();
  endtask

endmodule
