# rtl/ctrl/res_buf

Result buffer: a 16-entry LUT-RAM FIFO of result rows, each stored with its channel's M0 and s and a last-row flag.

- `res_buf.sv`: the module. Its header comment is the full spec for implementing it.
- Tested by `tb/ctrl/res_buf/tb_res_buf.sv`: `python tb/run.py sim tb_res_buf`.
- Static check: no block RAM.
