"""Replay positive seeds and require specific diagnostics from deliberate failures."""
import argparse
import pathlib
import subprocess
import sys

ROOT = pathlib.Path(__file__).resolve().parents[1]
BENCHES = ["tb_shared", "tb_axil_master", "tb_axis_negative", "tb_out_fifo", "tb_source_edges"]
TAGS = ["tb_shared", "tb_axil_master", "tb_out_fifo"] + [
    f"tb_source_edges_W{width}" for width in (1, 8, 64, 280)
]
CASES = [
    ("tb_shared", "negative", "compare", "intentional: got"),
    ("tb_shared", "negative", "cover_typo", "undeclared cover"),
    ("tb_shared", "negative", "cover_duplicate", "duplicate cover"),
    ("tb_shared", "negative", "cover_miss", "required coverage missing"),
    ("tb_shared", "negative", "width", "invalid width"),
    ("tb_shared", "negative", "zero_width", "invalid width"),
    ("tb_shared", "negative", "missing", "cannot open"),
    ("tb_shared", "negative", "empty", "empty file"),
    ("tb_shared", "negative", "malformed", "invalid hex"),
    ("tb_shared", "negative", "extra_token", "invalid line"),
    ("tb_shared", "negative", "overwide", "invalid line"),
    ("tb_shared", "negative", "gap_range", "invalid gap percent"),
    ("tb_shared", "negative", "ready_range", "invalid ready percent"),
    ("tb_shared", "negative", "sink_index", "invalid index"),
    ("tb_axis_negative", "violation", "valid", "rule 1"),
    ("tb_axis_negative", "violation", "data", "rule 2"),
    ("tb_axis_negative", "violation", "last", "rule 2"),
    ("tb_axil_master", "negative", "bresp", "bad BRESP"),
    ("tb_axil_master", "negative", "rresp", "bad read response"),
    ("tb_axil_master", "negative", "timeout", "transaction timeout"),
    ("tb_axil_master", "negative", "reset", "reset interrupted transaction"),
]


def run(args):
    return subprocess.run(args, cwd=ROOT, text=True, capture_output=True, timeout=300)


def binary(tag):
    path = ROOT / "build" / "sim" / tag / "sim"
    if not path.is_file():
        raise FileNotFoundError(f"Missing {path}; run python tb/run.py sim first")
    return str(path)


def positive_ok(result):
    return result.returncode == 0 and "PASS" in result.stdout.splitlines() and not any(
        line.startswith("SKIP") for line in result.stdout.splitlines()
    )


def negative_ok(result, diagnostic):
    return result.returncode != 0 and diagnostic in result.stdout + result.stderr


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--skip-build", action="store_true", help="reuse binaries from tb/run.py sim")
    args = parser.parse_args(argv)
    if not args.skip_build:
        result = run([sys.executable, "tb/run.py", "sim", *BENCHES])
        print(result.stdout + result.stderr)
        if result.returncode:
            return 1
    for seed in (1, 7, 29):
        for tag in TAGS:
            result = run([binary(tag), f"+seed={seed}"])
            print(f"--- {tag} seed={seed} ---")
            print(result.stdout + result.stderr)
            if not positive_ok(result):
                return 1
    for bench, arg, case, diagnostic in CASES:
        result = run([binary(bench), f"+{arg}={case}"])
        if not negative_ok(result, diagnostic):
            print(f"FAIL expected rejection: {case}\n{result.stdout}{result.stderr}")
            return 1
        print(f"PASS expected rejection: {bench}/{case}")
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except (OSError, subprocess.TimeoutExpired) as exc:
        print(f"FAIL regression infrastructure: {exc}", file=sys.stderr)
        sys.exit(1)
