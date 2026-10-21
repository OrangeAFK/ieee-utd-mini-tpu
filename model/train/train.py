"""Trains the float MNIST MLP, 784-128-64-10, and saves it for export. See README.md."""
import numpy as np
import torch


def load_mnist(root):
    """-> (train_x uint8 [60000, 784], train_y uint8 [60000], test_x uint8 [10000, 784], test_y uint8 [10000])."""
    raise NotImplementedError


def build_mlp():
    """-> torch.nn.Module: Linear(784, 128), ReLU, Linear(128, 64), ReLU, Linear(64, 10)."""
    raise NotImplementedError


def train_epochs(model, x, y, epochs, lr, batch):
    """Train in place on pixels / 255 with cross-entropy and Adam."""
    raise NotImplementedError


def evaluate(model, x, y):
    """-> float: test accuracy, 0 to 1, of the float model on uint8 pixels x."""
    raise NotImplementedError


def save_float(path, model, calib_x, test_x, test_y, float_acc):
    """Write the weights as [K, N] float32 arrays plus calibration and test data to an .npz."""
    raise NotImplementedError


def main():
    """Load, train, evaluate, save build/mlp_float.npz, print the float accuracy."""
    raise NotImplementedError
