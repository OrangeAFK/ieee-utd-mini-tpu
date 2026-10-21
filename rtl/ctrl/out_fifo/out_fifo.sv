// out_fifo: the output FIFO.
// Stores packed output words from the epilogue and plays them out on m_axis to the DMA,
// decoupling the two.
//
// Ports
//   name           dir    width  meaning
//   clk            in     1      the one clock
//   rst            in     1      synchronous, active high; empties the FIFO
//   ep_valid       in     1      ep_word and ep_last are valid
//   ep_word        in     64     word to store
//   ep_last        in     1      this is the layer's final word
//   of_ready       out    1      not full; a word is stored when ep_valid & of_ready
//   m_axis_tdata   out    64     head word
//   m_axis_tlast   out    1      head word's last bit
//   m_axis_tvalid  out    1      a head word is present
//   m_axis_tready  in     1      DMA takes the head word when tvalid & tready
//   last_sent      out    1      one-cycle pulse when the tlast word is accepted
//   ev_out_word    out    1      high on every accepted word: m_axis_tvalid & m_axis_tready
//   DEPTH          param  int    512 words
//
// Behaviour
//   1. Hold a DEPTH x 65-bit first-word-fall-through FIFO, entry = {last, word}.
//   2. Store {ep_last, ep_word} when ep_valid and of_ready are both high.
//   3. When the FIFO holds a word, m_axis_tvalid is high and m_axis_tdata, m_axis_tlast
//      show the oldest one, with no extra request.
//   4. Remove the head word when m_axis_tvalid and m_axis_tready are both high.
//   5. last_sent = m_axis_tvalid & m_axis_tready & m_axis_tlast.
//   6. ev_out_word = m_axis_tvalid & m_axis_tready.
//   7. of_ready is low when the FIFO is full, counting any word still in flight inside the
//      block RAM read pipeline.
//
// Timing
//   Valid/ready on both sides. m_axis_tvalid, tdata and tlast hold steady until tready.
//   A word written into an empty FIFO reaches m_axis a few cycles later; the exact number
//   is free. A write and a read in the same cycle both happen.
//   tkeep is not a port here; accel_top ties m_axis_tkeep to 8'hFF.
//   Reset: empty, m_axis_tvalid = 0.
//
// Resource target
//   1 RAMB36E1, no DSP.
//
// Done when
//   tb/ctrl/out_fifo/tb_out_fifo.sv prints PASS and synthesized alone it shows 1 RAMB36E1.
//
// Spec
//   docs/contracts.md, Contract 3. docs/architecture.md, section 6.11.
//   docs/verification.md, section 6.8.

module out_fifo #(
  parameter int DEPTH = 512
) (
  input  logic        clk,
  input  logic        rst,
  input  logic        ep_valid,
  input  logic [63:0] ep_word,
  input  logic        ep_last,
  output logic        of_ready,
  output logic [63:0] m_axis_tdata,
  output logic        m_axis_tlast,
  output logic        m_axis_tvalid,
  input  logic        m_axis_tready,
  output logic        last_sent,
  output logic        ev_out_word
);

endmodule
