// axis_src: AXI4-Stream source for benches.
// Plays queued words or a hex image onto a stream with random tvalid gaps, standing in for
// the DMA's MM2S channel.
//
// Ports
//   name    dir    width  meaning
//   clk     in     1      bench clock
//   rst     in     1      synchronous, active high; drops tvalid, keeps the queue
//   tdata   out    W      word on offer
//   tvalid  out    1      a word is on offer
//   tready  in     1      the receiver takes the word when tvalid & tready
//   tlast   out    1      the word's last flag
//   W       param  int    64
//   Tasks the bench calls (hierarchically, u_src.push(...)):
//   push(data, last)      append one word to the queue
//   load_hex(path)        append every line of a hex file; tlast on the file's final word
//   set_gap_pct(pct)      chance, 0 to 100, of holding tvalid low on any cycle; default 0
//   wait_empty()          return once every queued word has been accepted
//   clear()               drop every queued word not yet on offer
//
// Behaviour
//   1. Keep a queue of {last, data}.
//   2. Each clock: if no word is on offer and the queue is not empty, then with probability
//      gap_pct keep tvalid low; otherwise pop the next word, drive it, raise tvalid.
//   3. While tvalid is high and tready is low, hold tdata, tlast and tvalid unchanged.
//      Never change data while waiting.
//   4. On tvalid & tready the word is gone; go back to step 2 on the next cycle.
//   5. load_hex reads with tb_pkg::load_hex and pushes the low W bits of each value.
//   6. Use $urandom, so the bench seed controls the gaps.
//
// Timing
//   Drive outputs on the clock edge (nonblocking), so the receiver samples stable values.
//   Back-to-back words are possible with gap_pct = 0: one word per cycle while tready is high.
//   Reset: tvalid = 0 next cycle; queued words stay queued.
//
// Resource target
//   simulation only
//
// Done when
//   tb/ctrl/out_fifo/tb_out_fifo.sv passes using it (it drives the word side there), and
//   tb/common/axis_check/axis_check.sv reports no violation from it at gap_pct 0, 30 and 90.
//
// Spec
//   docs/contracts.md, Contract 3. docs/verification.md, section 4.

module axis_src #(
  parameter int W = 64
) (
  input  logic         clk,
  input  logic         rst,
  output logic [W-1:0] tdata,
  output logic         tvalid,
  input  logic         tready,
  output logic         tlast
);

  task automatic push(input logic [W-1:0] data, input logic last);
  endtask

  task automatic load_hex(input string path);
  endtask

  task automatic set_gap_pct(input int pct);
  endtask

  task automatic wait_empty();
  endtask

  task automatic clear();
  endtask

endmodule
