import pytest

pytestmark = pytest.mark.skip(reason="not implemented")


def test_layer_matches_loop_model():
    """layer() equals a plain triple-loop Python version on 1,000 small random cases, with -128 and 127 in every tensor."""


def test_tiles_then_requant_match_layer():
    """tile() over every (mt, nt), followed by sat25, the M0/s rounding shift and the clamp, reproduces layer() exactly."""
