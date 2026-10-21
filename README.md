# ieee-utd-mini-tpu

An 8×8 output-stationary INT8 matrix accelerator on a Digilent Cora Z7-07S (Zynq XC7Z007S), running a quantized MNIST MLP, 784-128-64-10, 64 images per run. The target is bit-exact agreement with a NumPy golden model, with measured throughput from hardware counters.

The Cortex-A9 runs a bare-metal driver that places three images per layer in DDR. A stock AXI DMA streams them through `accel_top`, which holds the 64-DSP array, a 64 KiB activation buffer, a ping-pong weight buffer, a two-lane requantizing epilogue and one layer FSM.

## Start here

1. `docs/contracts.md`: the five interfaces every part is built against.
2. `docs/architecture.md`: every block, port and timing rule.
3. `docs/verification.md`: how each block is tested and when it counts as done.
4. The README and header comment in your block's folder. They are written so you can implement the block from them alone.

## Layout

| Path | What |
| --- | --- |
| `docs/` | Specification |
| `model/` | Python: golden model, packers, vector generator, training, export |
| `rtl/mxu/` | The array: `pe`, `mxu`, `mxu_pkg.sv` |
| `rtl/ctrl/` | Everything around the array, one folder per block |
| `tb/` | Benches mirroring `rtl/`, shared components in `tb/common/`, runner `tb/run.py` |
| `vectors/` | Generated hex vectors; never hand-edited |
| `sw/` | Bare-metal driver and demo app |
| `hw/` | Vivado block-design scripts and constraints |
| `issues/` | Task drafts for the GitHub issue tracker |

## Running

Needs Verilator 5.020 or newer and Python 3.10 or newer. On Windows use WSL (Ubuntu 24.04: `sudo apt install verilator`).

```
pip install -r model/requirements.txt
python tb/run.py lint        # Verilator lint on rtl/
python tb/run.py sim         # every bench
pytest model                 # Python tests
```

CI runs the same three commands on every push and pull request. Every bench and Python test starts out as SKIP, which CI counts as a pass; the owner removes the skip in the pull request that makes it real.

Vivado is not part of CI. Synthesis checks run locally and their reports are committed next to the block.
