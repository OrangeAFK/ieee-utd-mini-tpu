"""Golden model, Contract 1 in docs/contracts.md.

layer() is the definition of a correct layer and tile() the definition of the array alone.
Hardware, driver and testbenches are right exactly when they match these bit for bit.
Editing this file is a contract change and goes through the lead.

Pass NumPy arrays with the dtypes in the comments. s must be a wide integer array
(int64): with a narrow dtype such as int8, 1 << (s - 1) wraps to 0 for large s.
"""
import numpy as np


def layer(A, W, bias, M0, s, z, lo, hi):
    # A: int8 [M,K]    W: int8 [K,N]    bias: int32 [N]
    # M0: uint16 [N]   s: int [N], 1..47
    # z, lo, hi: int8 scalars (output zero point, clamp bounds)
    acc = A.astype(np.int64) @ W.astype(np.int64) + bias     # must fit int32
    acc = np.clip(acc, -2**24, 2**24 - 1)                     # sat25
    r   = (acc * M0.astype(np.int64) + (1 << (s - 1))) >> s   # per channel, floor
    return np.clip(z + r, lo, hi).astype(np.int8)


def tile(a_words, w_words, bias8):
    # a_words: int8 [K,8], a_words[k,j] = activation for row j
    # w_words: int8 [K,8], w_words[k,c] = weight for channel c
    # bias8:   int32 [8]
    # returns  int32 [8,8], res[c,j] = bias8[c] + sum_k a_words[k,j] * w_words[k,c]
    res = w_words.astype(np.int64).T @ a_words.astype(np.int64) + bias8[:, None]
    return res.astype(np.int32)
