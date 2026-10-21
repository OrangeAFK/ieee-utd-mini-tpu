# rtl/ctrl/accel_top

The accelerator top level: one register port, two streams, the reset register, the stream demux and the bias mux, and one instance of every other block.

- `accel_top.sv`: the module. Its header comment is the full spec for implementing it.
- Tested by `tb/ctrl/accel_top/tb_accel_top.sv`: `python tb/run.py sim tb_accel_top`.
- Static check: 66 DSP48E1, 21 RAMB36E1, timing met at 10 ns. Commit the report here.
