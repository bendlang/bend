#!/usr/bin/env python3
"""Bound a closed capsule job; the child owns the campaign execution lock."""
import argparse
import hashlib
import json
from pathlib import Path
import sys
import time

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
sys.path.insert(0, str(ROOT/'selfhost/tools/performance/programs'))
from support import ExecutionGuard, save

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('mode', choices=['capture', 'verify'])
parser.add_argument('out', type=Path, help='New supervisor receipt directory outside raw evidence')
a = parser.parse_args()
producer = HERE/'preserve.py'
expected = '5d43f3c8e29ab448a51b5eb73d81b9e60729f3cc5533dfe89898a6c9d6e1710b'
assert hashlib.sha256(producer.read_bytes()).hexdigest() == expected
out = a.out.resolve()
raw = ROOT/'selfhost/build/phase35'
assert out != raw and raw not in out.parents
command = ['taskset', '-c', '3', sys.executable, str(producer), '--closed']
if a.mode == 'verify':
    command += ['--verify-only', '--check-source']
# A separate outer lock avoids acquiring the campaign flock twice: preserve.py
# itself holds the shared campaign lock throughout capture/source verification.
with ExecutionGuard(rss_mib=1024, available_mib=2048,
                    lock_path=HERE/'supervisor.lock') as guard:
    result = guard.run(command, out, time.monotonic()+600)
assert hashlib.sha256(producer.read_bytes()).hexdigest() == expected
print(json.dumps(result))
raise SystemExit(0 if result['complete'] else 1)
