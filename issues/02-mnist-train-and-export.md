MNIST network: train and export

## Goal

Train the demo MLP, 784-128-64-10, quantize it to the seven inputs `layer()` takes per layer, and report float and golden-model accuracy side by side. The demo vector sets are then rebuilt from the real model.

## Files

- `model/train/train.py`
- `model/export/export.py`, `model/export/test_export.py`
- `model/export/mlp_int8.npz`
- `docs/model_report.md`
- `vectors/layer_demo1_*`, `vectors/layer_demo2_*`, `vectors/layer_demo3_*`

## Interfaces

- `layer()`, Contract 1 in `docs/contracts.md`: W, bias, M0, s, z, lo, hi.
- Export formulas, input quantization, padding rules and the `.npz` keys: `model/export/README.md`.
- `build/mlp_float.npz` keys: `model/train/README.md`.
- Demo set generation from `mlp_int8.npz`: `model/gen_vectors/README.md`.

## Done when

- `pytest model/export` passes in CI with the skip line removed.
- `docs/model_report.md` shows float accuracy and golden-model accuracy over the 10,000 test images, and the largest |sum| seen per layer. No sum passes INT32; any sum at or beyond 2^24 is reported.
- `model/export/mlp_int8.npz` is committed, and `layer_demo1`, `layer_demo2` and `layer_demo3` are regenerated from it and committed.

## Out of scope

- Any change to `layer()`.
- A CNN or any network other than the 784-128-64-10 MLP.
- C headers for the board and the UART checker.
