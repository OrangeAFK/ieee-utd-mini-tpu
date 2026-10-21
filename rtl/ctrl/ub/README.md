# rtl/ctrl/ub

Unified buffer: 8,192 × 64-bit activation memory, written from the stream, read one word per cycle with a latency of 2.

- `ub.sv`: the module. Its header comment is the full spec for implementing it.
- Tested by `tb/ctrl/ub/tb_ub.sv`: `python tb/run.py sim tb_ub`.
- Static check: 16 RAMB36E1.
