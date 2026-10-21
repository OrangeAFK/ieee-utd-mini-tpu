// axis_sink: AXI4-Stream sink for benches.
// Collects words from a stream with random tready, standing in for the DMA's S2MM channel,
// and records where tlast fell.
//
// Ports
//   name    dir    width  meaning
//   clk     in     1      bench clock
//   rst     in     1      synchronous, active high; drops tready, keeps collected words
//   tdata   in     W      word on offer
//   tvalid  in     1      a word is on offer
//   tready  out    1      this sink takes the word when tvalid & tready
//   tlast   in     1      the word's last flag
//   W       param  int    64
//   Tasks and functions the bench calls (hierarchically, u_sink.get(...)):
//   set_ready_pct(pct)        chance, 0 to 100, of tready high on any cycle; default 100
//   stall(cycles)             hold tready low for that many cycles, then return to random
//   wait_words(n)             return once n words have been collected in total
//   wait_last()               return once a word with tlast has been collected
//   num_words()               function: words collected since the last clear()
//   get(idx, data, last)      the idx-th collected word and its tlast
//   last_index()              function: index of the first word with tlast, or -1
//   clear()                   forget every collected word
//
// Behaviour
//   1. Each clock, drive tready high with probability ready_pct, low otherwise, unless a
//      stall is in progress.
//   2. On tvalid & tready, append {tlast, tdata} to the collected list.
//   3. Check tdata and tlast for X when a word is taken; $fatal on X.
//   4. Use $urandom, so the bench seed controls tready.
//
// Timing
//   Sample tdata, tlast and tvalid on the clock edge. tready may change every cycle,
//   whatever tvalid does; a correct source tolerates that.
//   Reset: tready = 0 while rst is high.
//
// Resource target
//   simulation only
//
// Done when
//   tb/ctrl/out_fifo/tb_out_fifo.sv passes using it on m_axis.
//
// Spec
//   docs/contracts.md, Contract 3. docs/verification.md, section 4.

module axis_sink #(
  parameter int W = 64
) (
  input  logic         clk,
  input  logic         rst,
  input  logic [W-1:0] tdata,
  input  logic         tvalid,
  output logic         tready,
  input  logic         tlast
);

  task automatic set_ready_pct(input int pct);
  endtask

  task automatic stall(input int cycles);
  endtask

  task automatic wait_words(input int n);
  endtask

  task automatic wait_last();
  endtask

  function automatic int num_words();
  endfunction

  task automatic get(input int idx, output logic [W-1:0] data, output logic last);
  endtask

  function automatic int last_index();
  endfunction

  task automatic clear();
  endtask

endmodule
