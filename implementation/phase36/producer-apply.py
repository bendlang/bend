#!/usr/bin/env python3
"""Apply the reviewed private-producer source proposal only when root requests it."""
from pathlib import Path
import subprocess
import sys
root = Path(__file__).resolve().parents[2]
patch = Path(__file__).with_name('producer-source.patch')
if sys.argv[1:] != ['--apply']:
    raise SystemExit('usage: producer-apply.py --apply (root owns mutation/build scheduling)')
subprocess.run(['git', 'apply', '--check', str(patch)], cwd=root, check=True)
subprocess.run(['git', 'apply', str(patch)], cwd=root, check=True)
