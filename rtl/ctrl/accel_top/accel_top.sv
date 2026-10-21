// accel_top: the accelerator, the only custom block in the Vivado design.
// Exposes one AXI4-Lite register port and two 64-bit AXI4-Stream ports, and wires regfile,
// ub, wload, wb_pair, layer_fsm, mxu, res_buf, epilogue and out_fifo together.
//
// Ports
//   name           dir  width  meaning
//   clk            in   1      FCLK_CLK0, the one clock
//   aresetn        in   1      active low, synchronous to clk, from Processor System Reset
//   s_axi_awaddr   in   8      AXI4-Lite write address, to regfile
//   s_axi_awvalid  in   1
//   s_axi_awready  out  1
//   s_axi_wdata    in   32
//   s_axi_wstrb    in   4
//   s_axi_wvalid   in   1
//   s_axi_wready   out  1
//   s_axi_bresp    out  2
//   s_axi_bvalid   out  1
//   s_axi_bready   in   1
//   s_axi_araddr   in   8      AXI4-Lite read address, to regfile
//   s_axi_arvalid  in   1
//   s_axi_arready  out  1
//   s_axi_rdata    out  32
//   s_axi_rresp    out  2
//   s_axi_rvalid   out  1
//   s_axi_rready   in   1
//   s_axis_tdata   in   64     from DMA MM2S: a_img word (DEST = 0) or w_img word (DEST = 1)
//   s_axis_tvalid  in   1
//   s_axis_tready  out  1      dest ? wl_ready : 1
//   s_axis_tlast   in   1      ignored
//   s_axis_tkeep   in   8      ignored
//   m_axis_tdata   out  64     to DMA S2MM: o_img word, in index order
//   m_axis_tvalid  out  1
//   m_axis_tready  in   1
//   m_axis_tlast   out  1      high on the layer's final word only
//   m_axis_tkeep   out  8      always 8'hFF
//
// Behaviour
//   1. Reset register: rst <= ~aresetn | soft_reset. Feed rst to every block except regfile,
//      which takes aresetn directly.
//   2. Stream demux: ub_wr_valid = s_axis_tvalid & ~dest; wl_valid = s_axis_tvalid & dest;
//      s_axis_tready = dest ? wl_ready : 1'b1. s_axis_tdata goes to both ub and wload.
//   3. Bias mux: bias_in = cur_bias[shift_idx] when bias_sel = 0, nxt_bias[shift_idx] when
//      bias_sel = 1, zero otherwise.
//   4. m_axis_tkeep = 8'hFF.
//   5. Instantiate one of each block and connect them by the net table in
//      docs/architecture.md, section 5. mxu takes T and PIPE from mxu_pkg; layer_fsm takes
//      FLUSH_LAT and SHIFT_LAT from mxu_pkg.
//   No other logic lives here.
//
// Timing
//   Contract 3. DEST = 0: s_axis_tready is always 1. DEST = 1: s_axis_tready is low until
//   START and whenever the idle weight half is full. m_axis_tvalid holds until tready.
//   STATUS.DONE rises only after the tlast word was accepted.
//   The reset register adds one cycle between aresetn or soft_reset and rst.
//
// Resource target
//   66 DSP48E1, 21 RAMB36E1, no latches, timing met at 10 ns (then 8 ns).
//
// Done when
//   tb/ctrl/accel_top/tb_accel_top.sv prints PASS with the real mxu, the counter identities
//   hold in every run, and the synthesis report is committed.
//
// Spec
//   docs/architecture.md, sections 5 and 6.1. docs/contracts.md, Contracts 3 and 5.
//   docs/verification.md, section 6.11.

module accel_top (
  input  logic        clk,
  input  logic        aresetn,
  input  logic [7:0]  s_axi_awaddr,
  input  logic        s_axi_awvalid,
  output logic        s_axi_awready,
  input  logic [31:0] s_axi_wdata,
  input  logic [3:0]  s_axi_wstrb,
  input  logic        s_axi_wvalid,
  output logic        s_axi_wready,
  output logic [1:0]  s_axi_bresp,
  output logic        s_axi_bvalid,
  input  logic        s_axi_bready,
  input  logic [7:0]  s_axi_araddr,
  input  logic        s_axi_arvalid,
  output logic        s_axi_arready,
  output logic [31:0] s_axi_rdata,
  output logic [1:0]  s_axi_rresp,
  output logic        s_axi_rvalid,
  input  logic        s_axi_rready,
  input  logic [63:0] s_axis_tdata,
  input  logic        s_axis_tvalid,
  output logic        s_axis_tready,
  input  logic        s_axis_tlast,
  input  logic [7:0]  s_axis_tkeep,
  output logic [63:0] m_axis_tdata,
  output logic        m_axis_tvalid,
  input  logic        m_axis_tready,
  output logic        m_axis_tlast,
  output logic [7:0]  m_axis_tkeep
);

endmodule
