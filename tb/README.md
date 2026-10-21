# tb

Testbenches, one folder per block, mirroring `rtl/`. Shared components in `common/`.

```
python tb/run.py lint                     Verilator lint on every RTL module
python tb/run.py sim                      build and run every bench
python tb/run.py sim tb_ub                one bench
python tb/run.py sim tb_mxu -- +seed=7    replay a seed
```

`run.py` builds each `tb_*.sv` with Verilator 5 together with all of `rtl/` and `tb/common/`, runs it from the repository root, and passes it when it prints `PASS` or `SKIP`. Builds land in `build/sim/`. Parameter sets for `tb_pe` and `tb_mxu` are listed at the top of `run.py`.

Every bench starts as `$display("SKIP: not implemented"); $finish;`. Delete that line in the pull request that makes the bench real. Bench rules: `docs/verification.md`, section 2. On Windows, run these inside WSL.
