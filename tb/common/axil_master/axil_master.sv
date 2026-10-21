// axil_master: AXI4-Lite master for benches.
// Gives a bench write(addr, data) and read(addr, data) tasks, standing in for the CPU on
// GP0, with random delays on every channel.
//
// Ports
//   name           dir    width  meaning
//   clk            in     1      bench clock
//   rst            in     1      synchronous, active high; all valids low
//   m_axi_awaddr   out    AW     write address
//   m_axi_awvalid  out    1
//   m_axi_awready  in     1
//   m_axi_wdata    out    32     write data
//   m_axi_wstrb    out    4      always 4'hF
//   m_axi_wvalid   out    1
//   m_axi_wready   in     1
//   m_axi_bresp    in     2      checked: must be 2'b00
//   m_axi_bvalid   in     1
//   m_axi_bready   out    1
//   m_axi_araddr   out    AW     read address
//   m_axi_arvalid  out    1
//   m_axi_arready  in     1
//   m_axi_rdata    in     32     read data
//   m_axi_rresp    in     2      checked: must be 2'b00
//   m_axi_rvalid   in     1
//   m_axi_rready   out    1
//   AW             param  int    8
//   Tasks the bench calls (hierarchically, u_axil.write(...)):
//   write(addr, data)     one write; returns after the response
//   read(addr, data)      one read; returns the data after the response
//   set_max_delay(n)      random delays, 0 to n cycles, on every channel; default 0
//   set_order(mode)       0 random, 1 address before data, 2 data before address, 3 together
//
// Behaviour
//   1. write: wait a random delay, raise awvalid with awaddr; independently wait a random
//      delay, raise wvalid with wdata. The order of the two follows set_order. Drop each
//      valid after its ready. Then hold bready low for a random delay, raise it, take the
//      response, check bresp = OKAY.
//   2. read: wait a random delay, raise arvalid with araddr, drop it after arready. Hold
//      rready low for a random delay, raise it, take rdata, check rresp = OKAY.
//   3. Never change addr or data while its valid is high and ready is low.
//   4. Calls are sequential; one transfer at a time.
//   5. A response that never comes is a hang: $fatal after 10,000 cycles.
//
// Timing
//   Drive outputs on the clock edge (nonblocking). Delays use $urandom, so the bench seed
//   controls them. With max delay 0 and mode 3, a write takes about 3 cycles.
//   Reset: all valids and readies low.
//
// Resource target
//   simulation only
//
// Done when
//   tb/ctrl/regfile/tb_regfile.sv passes using it, covering all four set_order modes.
//
// Spec
//   docs/contracts.md, Contract 5. docs/verification.md, section 4.

module axil_master #(
  parameter int AW = 8
) (
  input  logic          clk,
  input  logic          rst,
  output logic [AW-1:0] m_axi_awaddr,
  output logic          m_axi_awvalid,
  input  logic          m_axi_awready,
  output logic [31:0]   m_axi_wdata,
  output logic [3:0]    m_axi_wstrb,
  output logic          m_axi_wvalid,
  input  logic          m_axi_wready,
  input  logic [1:0]    m_axi_bresp,
  input  logic          m_axi_bvalid,
  output logic          m_axi_bready,
  output logic [AW-1:0] m_axi_araddr,
  output logic          m_axi_arvalid,
  input  logic          m_axi_arready,
  input  logic [31:0]   m_axi_rdata,
  input  logic [1:0]    m_axi_rresp,
  input  logic          m_axi_rvalid,
  output logic          m_axi_rready
);

  task automatic write(input logic [AW-1:0] addr, input logic [31:0] data);
  endtask

  task automatic read(input logic [AW-1:0] addr, output logic [31:0] data);
  endtask

  task automatic set_max_delay(input int n);
  endtask

  task automatic set_order(input int mode);
  endtask

endmodule
