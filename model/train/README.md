# model/train

Trains the demo network, a float MLP 784-128-64-10 on MNIST, and saves it for `model/export`. This is the only part of the project that uses PyTorch.

```
pip install torch torchvision
python -m model.train
```

## To implement

The functions in `train.py`.

- `load_mnist(root)`: MNIST through torchvision, returned as NumPy: images flattened to uint8 [n, 784], labels uint8 [n].
- `build_mlp()`: `Linear(784, 128)`, ReLU, `Linear(128, 64)`, ReLU, `Linear(64, 10)`. No other layers; the hardware runs exactly these three.
- `train_epochs`: input is `pixel / 255` as float32. This matches the integer input the hardware sees, `pixel − 128` with scale 1/255 and zero point −128. Cross-entropy, Adam. A few epochs reach about 97 to 98%.
- `evaluate`: accuracy over the 10,000 test images.
- `save_float(path, ...)`: an `.npz` with keys
  - `w1` [784, 128], `b1` [128], `w2` [128, 64], `b2` [64], `w3` [64, 10], `b3` [10], all float32. Weights are stored [K, N], the transpose of `nn.Linear.weight`.
  - `calib_x` uint8 [1000, 784]: training images for calibration.
  - `test_x` uint8 [10000, 784], `test_y` uint8 [10000].
  - `float_acc`: the float test accuracy.
- `main()`: fix the seed, train, print the accuracy, write `build/mlp_float.npz`.

`build/` is not committed. The export step needs nothing from PyTorch, only this file.

Done when `build/mlp_float.npz` exists and the float accuracy is recorded in `docs/model_report.md` by `model/export`.
