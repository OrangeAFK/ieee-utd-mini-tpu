"""Run shared/FIFO regressions and require specific negative-test diagnostics."""
import pathlib
import subprocess
import sys

ROOT = pathlib.Path(__file__).resolve().parents[1]

def run(args):
    return subprocess.run(args, cwd=ROOT, text=True, capture_output=True, timeout=300)

def main():
    result = run([sys.executable, "tb/run.py", "sim", "tb_shared", "tb_axis_negative", "tb_out_fifo"])
    print(result.stdout + result.stderr)
    if result.returncode:
        return 1
    cases = [
        ("tb_shared", "negative", "compare", "intentional: got"),
        ("tb_shared", "negative", "cover_typo", "undeclared cover"),
        ("tb_shared", "negative", "cover_miss", "required coverage missing"),
        ("tb_shared", "negative", "width", "invalid width"),
        ("tb_shared", "negative", "missing", "cannot open"),
        ("tb_shared", "negative", "empty", "empty file"),
        ("tb_shared", "negative", "malformed", "invalid hex"),
        ("tb_axis_negative", "violation", "valid", "rule 1"),
        ("tb_axis_negative", "violation", "data", "rule 2"),
        ("tb_axis_negative", "violation", "last", "rule 2"),
    ]
    for bench, arg, case, diagnostic in cases:
        result = run([str(ROOT / "build" / "sim" / bench / "sim"), f"+{arg}={case}"])
        if result.returncode == 0 or diagnostic not in result.stdout + result.stderr:
            print(f"FAIL expected rejection: {case}\n{result.stdout}{result.stderr}")
            return 1
        print(f"PASS expected rejection: {case}")
    return 0

if __name__ == "__main__":
    sys.exit(main())
