# rtl/ctrl/wload

Weight loader: parses the weight stream into parameter sets and weight words, and owns the ping-pong state (`active`, `nxt_valid`).

- `wload.sv`: the module. Its header comment is the full spec for implementing it.
- Tested by `tb/ctrl/wload/tb_wload.sv`: `python tb/run.py sim tb_wload`.
- That bench runs `wload` together with `wb_pair`.
