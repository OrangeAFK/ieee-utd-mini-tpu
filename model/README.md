# model

Python packages, one folder each. Run everything from the repository root.

| Package | What it does | Run |
| --- | --- | --- |
| `golden/` | `layer()` and `tile()`, the numerical reference | imported |
| `pack/` | Tensors to and from the DDR images | imported |
| `gen_vectors/` | Writes `vectors/` and `sw/demo/data/reorder_test.h` | `python -m model.gen_vectors` |
| `train/` | Trains the float MLP | `python -m model.train` |
| `export/` | Quantizes it and reports accuracy | `python -m model.export` |

Tested with `pytest model`; each package keeps its tests next to its code. `pip install -r model/requirements.txt` covers everything except `train/`, which also needs `torch` and `torchvision`.
