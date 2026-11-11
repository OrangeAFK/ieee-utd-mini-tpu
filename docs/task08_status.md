# Task 08 verification status

Implemented on `tb/shared-components`:
- Shared package: cached seed, case-inequality comparisons, width-checked X detection,
  strict hex loading, declared coverage counters and final verdict.
- Stream source/sink: random gaps and backpressure, queue and collected-word APIs.
- Stream checker: stalled valid/data/last stability and unknown data checks.
- AXI-Lite master: ordered address/data channels, randomized delays and watchdog.
- Output FIFO: synchronous RAM read with held output, total occupancy limited to DEPTH.
- Shared component and FIFO benches; explicit expected-failure regression runner.

## Run on a machine with Verilator

```sh
python tb/run.py lint
python tb/test_shared.py
python tb/run.py sim tb_shared tb_out_fifo -- +seed=7
python tb/run.py sim tb_shared tb_out_fifo -- +seed=29
python tb/run.py sim
```

The dedicated runner checks diagnostic text as well as nonzero exit status, so a watchdog
or unrelated simulator crash cannot pass an expected-failure test.

## Remaining acceptance work

These changes have **not** passed a simulator. Local execution stops because Verilator
is unavailable. Dependency installation also fails because external DNS cannot resolve.
No GitHub Actions runs exist on the fork as of this work session.
The AXI-Lite master still needs its own slave-model regression, including all ordering
modes, randomized slave readiness, timeout/error responses and reset.
Run the full regression and fix any compile, lint or behavioral failures before merge.
Run the pinned Vivado toolchain and commit actual out_fifo utilization/timing reports;
one RAMB36E1 is a target, not a measured result. Compile shared utilities with the Vivado
simulator too; its four-state run is needed for meaningful X/Z verification.

Queue-mutating source/sink API calls must be made away from posedge (normally negedge).
Reset discards the source's active offer and preserves only its pending queue; clear()
discards pending words but preserves the active offer.

The connected GitHub app can push the fork but receives HTTP 403 when opening an upstream
PR. The branch comparison can be used to open the PR manually:
https://github.com/OrangeAFK/ieee-utd-mini-tpu/compare/main...yashbhdne:ieee-utd-mini-tpu:tb/shared-components?expand=1

Task 08 is not complete until the required evidence is available. Task 02 has not been
started, preserving the lead's requested order. No model accuracy, synthesis count or
PASS output has been fabricated.
