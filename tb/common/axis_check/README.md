# tb/common/axis_check

AXI4-Stream checker: `tvalid` holds until `tready`, data and `tlast` stable while waiting, no X while valid.

- `axis_check.sv`: the component. Its header comment is the full spec, including the tasks benches call.
- Tested by use in `tb_out_fifo` and `tb_accel_top`.
