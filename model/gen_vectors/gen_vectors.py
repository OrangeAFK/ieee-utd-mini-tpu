"""Writes every test-vector set under vectors/ from the golden model. See README.md."""
import numpy as np

from model.golden import layer, tile
from model.pack import pack_acts, pack_weights, unpack_out, reorder


def to_hex(value, digits):
    """int -> str: value masked to 4*digits bits, upper-case hex, zero-padded, no prefix."""
    raise NotImplementedError


def write_hex(path, values, digits):
    """Write one to_hex(v, digits) per line to path."""
    raise NotImplementedError


def gen_tile(name, K, rng, fill=None):
    """Write tile_<name>_{a,w,bias,res}.hex for one random tile; every operand = fill if given."""
    raise NotImplementedError


def epi_corners():
    """-> list of (row int32 [8], M0, s, last) covering every epilogue corner case, plus (z, lo, hi)."""
    raise NotImplementedError


def epi_random(rng, n):
    """-> list of n random (row int32 [8], M0, s, last), plus (z, lo, hi)."""
    raise NotImplementedError


def gen_epi(name, entries, z, lo, hi):
    """Write epi_<name>_{in,out,cfg}.hex; expected words come from layer()."""
    raise NotImplementedError


def random_layer(M, K, N, rng):
    """-> (A, W, bias, M0, s, z, lo, hi) for a random layer whose sums fit INT32."""
    raise NotImplementedError


def gen_layer(name, A, W, bias, M0, s, z, lo, hi):
    """Write layer_<name>_{a,w,o,cfg}.hex; o_img comes from layer()."""
    raise NotImplementedError


def gen_reorder_header(path, rng):
    """Write a C header with one o_img and its reorder() as uint64_t arrays."""
    raise NotImplementedError


def main():
    """Generate every set listed in README.md with a fixed seed."""
    raise NotImplementedError
