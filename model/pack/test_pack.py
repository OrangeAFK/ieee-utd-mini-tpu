import pytest

pytestmark = pytest.mark.skip(reason="not implemented")


def test_round_trip_all_images():
    """Packing then unpacking returns the original tensor for a_img, the weights and parameters of w_img, and o_img."""


def test_chaining_rule():
    """reorder() of a layer's o_img equals pack_acts() of that layer's unpacked output."""


def test_contract2_worked_example():
    """M = 8, K = 2, N = 8 gives the exact words listed in model/pack/README.md."""
