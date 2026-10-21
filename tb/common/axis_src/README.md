# tb/common/axis_src

AXI4-Stream source: plays queued words or a hex file with random `tvalid` gaps, never changing data while waiting.

- `axis_src.sv`: the component. Its header comment is the full spec, including the tasks benches call.
- Tested by use in `tb_out_fifo`, `tb_wload` and `tb_accel_top`.
