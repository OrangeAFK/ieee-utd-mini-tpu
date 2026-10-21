# Contributing

## Work

- Each task is a GitHub issue with Goal, Files, Interfaces, Done when and Out of scope. One owner per block; pairs are fine, shared ownership is not.
- One branch per block or task, named after it: `ctrl/ub`, `mxu/audit`, `model/golden`.
- Never commit to `main` directly. Open a pull request; CI must be green.

## Done means the bench passes

A block is done when its bench prints PASS in CI and its static check is committed, not when the code is written.

- Every bench starts with `$display("SKIP: not implemented"); $finish;`. Delete that line in the pull request that makes the bench real. Every Python test file starts with a `pytestmark` skip; same rule.
- Follow the bench rules in `docs/verification.md`, section 2: self-checking, independent reference, seeded randomness, random backpressure, a reset in the middle, X checks, cover counters.
- A bug found at a higher level gets a unit test that reproduces it before the fix merges.
- In the pull request, paste the PASS line and the cover-counter printout.

## Contracts

`docs/contracts.md` is frozen. A change to anything in it, including a port name, a width, a word layout, a register bit or `model/golden/golden.py`, goes through the lead as its own pull request. Port lists in the RTL stubs follow the contracts; do not change them on your own.

## Vectors

Files in `vectors/` come from `python -m model.gen_vectors`. Never edit them by hand. Change the generator, regenerate, and commit both.

## SystemVerilog

- `logic`, `always_ff`, `always_comb`. One clock, `clk`. Synchronous, active-high `rst` (`regfile` uses `aresetn`).
- No latches. No `*` outside `pe` and `epilogue`; addresses come from counters and adders.
- Read timing constants from `mxu_pkg` or parameters, never as literals.
- No comment line may start with the word "verilator"; Verilator treats it as a directive.
- Lint clean: `python tb/run.py lint`.

## Python

- NumPy for everything except training, which uses PyTorch.
- Cast INT8 arrays to int64 before arithmetic. Never use `round()` where the hardware rounds; use the integer formula in Contract 1.
- Run from the repository root: `python -m model.<package>`, `pytest model`.

## Vivado

Use the one pinned Vivado version. Commit synthesis and utilization reports next to the block they describe, and Tcl scripts in `hw/`, never project folders.
