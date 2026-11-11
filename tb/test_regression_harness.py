"""Tests for the regression harness's pass/failure acceptance rules."""
import subprocess
import unittest

from test_shared import negative_ok, positive_ok


class VerdictTests(unittest.TestCase):
    def result(self, code=0, stdout="", stderr=""):
        return subprocess.CompletedProcess([], code, stdout, stderr)

    def test_positive_requires_clean_exit_and_exact_pass_line(self):
        self.assertTrue(positive_ok(self.result(stdout="cover x = 1\nPASS\n")))
        self.assertFalse(positive_ok(self.result(stdout="NOT PASS\n")))
        self.assertFalse(positive_ok(self.result(1, "PASS\n")))
        self.assertFalse(positive_ok(self.result(stdout="SKIP: stub\nPASS\n")))

    def test_negative_requires_both_failure_and_specific_diagnostic(self):
        self.assertTrue(negative_ok(self.result(1, stderr="bad BRESP 10"), "bad BRESP"))
        self.assertFalse(negative_ok(self.result(stdout="bad BRESP"), "bad BRESP"))
        self.assertFalse(negative_ok(self.result(1, stderr="watchdog"), "bad BRESP"))


if __name__ == "__main__":
    unittest.main()
