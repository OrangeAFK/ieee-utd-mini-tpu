// wb_pair: the weight block pair.
// Two 1,024-word weight memories. The array reads half `active` for every tile of the
// current nt while wload fills the other half for the next nt.
//
// Ports
//   name    dir    width  meaning
//   clk     in     1      the one clock
//   rst     in     1      synchronous, active high; the memories need no reset
//   we      in     1      write enable
//   waddr   in     AW     write address, k
//   wdata   in     64     weight word
//   active  in     1      half that reads use; writes go to half ~active
//   raddr   in     AW     read address, k from layer_fsm
//   rdata   out    64     w_word to the mxu; valid RD_LAT = 2 cycles after raddr
//   AW      param  int    10; each half holds 2**AW = 1,024 words
//
// Behaviour
//   1. Hold two memories of 1,024 x 64 bits, half 0 and half 1. One 2,048-word memory
//      addressed {half, addr} works as well.
//   2. When we is high: half[~active][waddr] <= wdata.
//   3. Every cycle: register half[active][raddr] into a read register, then into an
//      output register that drives rdata. Same latency as ub, so a_word and w_word stay
//      aligned.
//
// Timing
//   raddr presented in cycle t gives rdata in cycle t + 2. A new address every cycle.
//   active changes only in layer_fsm's SWAP state, when no read is in flight, so the read
//   mux needs no special care. Sampling active with the address is fine.
//   No handshake. Reset has no visible effect.
//
// Resource target
//   4 RAMB36E1, no LUT RAM.
//
// Done when
//   tb/ctrl/wb_pair/tb_wb_pair.sv prints PASS and synthesized alone it shows 4 RAMB36E1.
//   tb/ctrl/wload/tb_wload.sv, which uses this block, also passes.
//
// Spec
//   docs/architecture.md, section 6.5. docs/verification.md, section 6.5.

module wb_pair #(
  parameter int AW = 10
) (
  input  logic          clk,
  input  logic          rst,
  input  logic          we,
  input  logic [AW-1:0] waddr,
  input  logic [63:0]   wdata,
  input  logic          active,
  input  logic [AW-1:0] raddr,
  output logic [63:0]   rdata
);

endmodule
