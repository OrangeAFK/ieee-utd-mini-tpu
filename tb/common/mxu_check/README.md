# tb/common/mxu_check

Contract 4 checker: burst lengths, no `in_valid` during a shift, FLUSH_LAT before a shift, SHIFT_LAT to `res_valid`, no X in `res_row`.

- `mxu_check.sv`: the component. Its header comment is the full spec, including the tasks benches call.
- Tested by use in `tb_mxu`, `tb_layer_fsm` and `tb_accel_top`.
