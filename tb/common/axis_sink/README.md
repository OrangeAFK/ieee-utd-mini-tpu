# tb/common/axis_sink

AXI4-Stream sink: collects words with random `tready` and records where `tlast` fell.

- `axis_sink.sv`: the component. Its header comment is the full spec, including the tasks benches call.
- Tested by use in `tb_out_fifo` and `tb_accel_top`.
