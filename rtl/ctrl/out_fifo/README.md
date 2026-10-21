# rtl/ctrl/out_fifo

Output FIFO: 512 × 65-bit first-word-fall-through FIFO driving `m_axis`.

- `out_fifo.sv`: the module. Its header comment is the full spec for implementing it.
- Tested by `tb/ctrl/out_fifo/tb_out_fifo.sv`: `python tb/run.py sim tb_out_fifo`.
- Static check: 1 RAMB36E1.
