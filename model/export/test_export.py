import pytest

pytestmark = pytest.mark.skip(reason="not implemented")


def test_quantize_input():
    """Pixels 0, 128 and 255 become -128, 0 and 127."""


def test_weights_symmetric():
    """Every quantized weight lies in [-127, 127] and each channel's largest |w| maps to 127."""


def test_m0_in_range():
    """choose_m0_s gives 2**15 <= M0 < 2**16 and M0 / 2**s within 2**-15 relative of the scale."""


def test_shift_capped_at_47():
    """A scale so small that s would pass 47 gets s = 47 and a smaller M0."""


def test_fold_bias_example():
    """fold_bias reproduces the worked example in model/export/README.md."""


def test_padded_channels():
    """Layer 3's channels 10 to 15 have zero weights, zero bias, M0 = 0 and s = 1."""


def test_relu_lo_equals_z():
    """Layers 1 and 2 have lo = z and hi = 127; layer 3 has lo = -128 and hi = 127."""


def test_sums_fit_int32():
    """check_sums raises on a layer whose sum passes INT32 and warns on one that reaches 2**24."""


def test_golden_matches_float():
    """On a tiny random float network, run_network's argmax agrees with the float argmax on most inputs."""
