// res_buf: the result buffer.
// Catches the 8 rows of each shift burst from the mxu and holds them until the epilogue is
// ready, each row stored with the scale (M0, s) of its channel.
//
// Ports
//   name           dir    width   meaning
//   clk            in     1       the one clock
//   rst            in     1       synchronous, active high; empties the buffer, burst index = 0
//   res_valid      in     1       a row of 8 sums from the mxu
//   res_row        in     256     lane j = bits [32j+31:32j], INT32 sum for row j
//   rb_discard     in     1       this burst is the preload; drop its rows
//   rb_last        in     1       this burst is the layer's final tile
//   cur_m0         in     8 x 16  M0 of channel c of the CURRENT block; [c] = channel c
//   cur_sh         in     8 x 6   s of channel c of the CURRENT block
//   can_take_tile  out    1       at least 8 entries are free
//   rb_valid       out    1       a head entry is present
//   rb_row         out    256     head entry: the row
//   rb_m0          out    16      head entry: M0
//   rb_sh          out    6       head entry: s
//   rb_last_o      out    1       head entry: last row of the layer
//   rb_pop         in     1       head entry consumed; only high when rb_valid is high
//   DEPTH          param  int     16 entries
//
// Behaviour
//   State: a DEPTH x 279-bit FIFO, entry = {last, sh[5:0], m0[15:0], row[255:0]}, read and
//   write pointers, a fill count, and a 3-bit burst index c.
//   1. c counts res_valid cycles 0 to 7 and wraps. It counts discarded bursts too.
//   2. When res_valid is high and rb_discard is low, push
//      {rb_last & (c == 7), cur_sh[c], cur_m0[c], res_row}.
//   3. Capture cur_m0[c] and cur_sh[c] at push time. wload may overwrite that parameter set
//      before the epilogue reads the row.
//   4. When rb_pop is high, drop the head entry. A push and a pop in the same cycle both
//      happen and the count is unchanged.
//   5. rb_valid = count != 0. rb_row, rb_m0, rb_sh, rb_last_o show the head entry
//      (first-word fall-through; a combinational LUT RAM read is fine).
//   6. can_take_tile = (DEPTH - count) >= 8.
//
// Timing
//   A pushed entry is visible at the head the cycle after the push, at the earliest.
//   layer_fsm starts a burst only when can_take_tile is high, so a push never meets a full
//   buffer. No backpressure toward the mxu.
//   rb_discard and rb_last are aligned with res_valid.
//   Reset: count = 0, pointers = 0, c = 0.
//
// Resource target
//   No block RAM, no DSP. Storage in LUT RAM.
//
// Done when
//   tb/ctrl/res_buf/tb_res_buf.sv prints PASS.
//
// Spec
//   docs/architecture.md, section 6.9. docs/verification.md, section 6.6.

module res_buf #(
  parameter int DEPTH = 16
) (
  input  logic             clk,
  input  logic             rst,
  input  logic             res_valid,
  input  logic [255:0]     res_row,
  input  logic             rb_discard,
  input  logic             rb_last,
  input  logic [7:0][15:0] cur_m0,
  input  logic [7:0][5:0]  cur_sh,
  output logic             can_take_tile,
  output logic             rb_valid,
  output logic [255:0]     rb_row,
  output logic [15:0]      rb_m0,
  output logic [5:0]       rb_sh,
  output logic             rb_last_o,
  input  logic             rb_pop
);

endmodule
