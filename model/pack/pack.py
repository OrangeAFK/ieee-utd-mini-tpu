"""Packers for Contract 2: tensors to and from the 64-bit DDR images. See README.md."""
import numpy as np


def pack_acts(A):
    """int8 [M, K] -> uint64 [M_T * K]: a_img, word mt*K + k holds A[8mt + j, k] in byte j."""
    raise NotImplementedError


def pack_weights(W, bias, M0, s):
    """int8 [K, N], int32 [N], uint16 [N], int [N] -> uint64 [N_T * (K + 8)]: w_img."""
    raise NotImplementedError


def unpack_out(o_img, M, N):
    """uint64 [M_T * N] -> int8 [M, N]: o_img word (nt*M_T + mt)*8 + c, byte j = y[8mt + j, 8nt + c]."""
    raise NotImplementedError


def reorder(o_img, m_tiles, n_tiles):
    """uint64 [M_T * N] -> uint64 [M_T * N]: next layer's a_img, a_next[mt*N + 8nt + c] = o_img[(nt*M_T + mt)*8 + c]."""
    raise NotImplementedError
