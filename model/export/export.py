"""Quantizes the float MLP into the seven layer() inputs per layer. See README.md."""
import numpy as np

from model.golden import layer


def quantize_input(pixels):
    """uint8 [M, 784] -> int8 [M, 784]: pixel - 128 (s_a = 1/255, zp_a = -128)."""
    raise NotImplementedError


def quantize_weights(w):
    """float [K, N] -> (int8 [K, N] in [-127, 127], float [N] s_w): per-channel symmetric."""
    raise NotImplementedError


def output_qparams(real_min, real_max):
    """-> (float s_o, int z): INT8 scale and zero point covering [min(real_min, 0), max(real_max, 0)]."""
    raise NotImplementedError


def choose_m0_s(scale):
    """float [N] -> (uint16 [N] M0, int64 [N] s): M0 = round(scale * 2**s), 2**15 <= M0 < 2**16, s <= 47."""
    raise NotImplementedError


def fold_bias(real_b, s_a, s_w, zp_a, W):
    """-> int32 [N]: round(real_b / (s_a * s_w)) - zp_a * sum_k W[k, n]."""
    raise NotImplementedError


def float_forward(params, pixels):
    """-> list of three float arrays: each layer's output (after ReLU for layers 1 and 2)."""
    raise NotImplementedError


def export_layer(w, b, s_a, zp_a, s_o, z, relu):
    """-> dict W, bias, M0, s, z, lo, hi for layer(), N padded to a multiple of 8."""
    raise NotImplementedError


def check_sums(A, L):
    """-> int: largest |sum| of layer L on input A; asserts INT32, warns at 2**24 or above."""
    raise NotImplementedError


def run_network(layers, A):
    """int8 [M, 784] -> int8 [M, 16]: the three layers chained through layer()."""
    raise NotImplementedError


def golden_accuracy(layers, test_x, test_y):
    """-> float: accuracy of run_network over the test set, batches of 64, argmax over channels 0 to 9."""
    raise NotImplementedError


def save_export(path, layers, batch_x, batch_y):
    """Write the three layers and one 64-image input batch to an .npz."""
    raise NotImplementedError


def write_report(path, float_acc, golden_acc, max_sums):
    """Write docs/model_report.md: both accuracies and the largest sum per layer."""
    raise NotImplementedError


def main():
    """build/mlp_float.npz -> model/export/mlp_int8.npz and docs/model_report.md."""
    raise NotImplementedError
