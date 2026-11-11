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
Upstream PR #5 now exists. Its latest CI run requires maintainer approval; no HDL
test results are available yet.
The AXI-Lite master now has an independent slave-model regression covering all ordering
modes, randomized and coupled slave readiness, timeout/error responses and reset.
Review found and fixed a potential deadlock: address/data order must order the offers,
not require the first channel to handshake before offering the second. The slave model
includes coupled readiness to reproduce this case. This regression still needs execution.
Parameterized source tests cover W=1/8/64/280, gap=100, bubble-free gap=0 traffic,
hex truncation and no final newline, timed sink stalls, and reset with pending data.
The regression runner replays seeds 1/7/29 and verifies 21 expected failure cases.
Its verdict acceptance logic passes two local Python unit tests. Python compilation and
git diff --check also pass. These are not evidence of HDL correctness.
The prepared CI update invokes the extended runner after the full simulation build and
retains successful PASS/coverage output in the CI logs.
Run the full regression and fix any compile, lint or behavioral failures before merge.
Run the pinned Vivado toolchain and commit actual out_fifo utilization/timing reports;
one RAMB36E1 is a target, not a measured result. Compile shared utilities with the Vivado
simulator too; its four-state run is needed for meaningful X/Z verification.

Queue-mutating source/sink API calls must be made away from posedge (normally negedge).
Reset discards the source's active offer and preserves only its pending queue; clear()
discards pending words but preserves the active offer.

The connected GitHub app can push the fork. The user opened the upstream draft PR:
https://github.com/OrangeAFK/ieee-utd-mini-tpu/pull/5
The CI workflow update has been pushed and verified on the remote branch. The lead
must approve the latest run after these changes. No additional PR is needed.

Task 08 is not complete until the required evidence is available. Task 02 has not been
started, preserving the lead's requested order. No model accuracy, synthesis count or
PASS output has been fabricated.
