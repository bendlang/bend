#!/usr/bin/env python3
"""Freeze exact CPU1 adaptations of final gate metadata/launch tools; no gates."""
from pathlib import Path
import hashlib
import json
import sys

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
out = Path(sys.argv[1]).resolve()
out.mkdir(parents=True, exist_ok=False)


def identity(file):
    raw = file.read_bytes()
    return {'file': str(file.resolve()), 'sha256': hashlib.sha256(raw).hexdigest(), 'bytes': len(raw)}


rows = []
for source_name, target_name, changes in [
    ('inspect-final-integration-plan.py', 'plan.py', [
        ('ROOT = Path(__file__).resolve().parents[4]', 'ROOT = Path(' + repr(str(ROOT)) + ')', 1),
        ('HERE = Path(__file__).resolve().parent', 'HERE = Path(' + repr(str(HERE)) + ')', 1),
        ('("\'4\'", "\'7\'")', '("\'4\'", "\'1\'")', 1),
        ('CPU7', 'CPU1', 3),
        ('attempt, mode, out / mode], 7,', 'attempt, mode, out / mode], 1,', 1),
        ("['taskset', '-c', '7', NODE", "['taskset', '-c', '1', NODE", 1),
        ("out / 'worker-admission'], 7,", "out / 'worker-admission'], 1,", 1),
        ("out / 'corpus'], 7,", "out / 'corpus'], 1,", 1),
        ("out / 'component', out / 'hvm'], 7,", "out / 'component', out / 'hvm'], 1,", 1),
    ]),
    ('inspect-final-gates.py', 'gates.py', [
        ('cpu in [4, 7]', 'cpu in [4, 1]', 1),
        ('root = Path(__file__).resolve().parents[4]', 'root = Path(' + repr(str(ROOT)) + ')', 1),
    ]),
]:
    source = HERE / source_name
    original = source.read_text()
    text = original
    for before, after, expected in changes:
        assert text.count(before) == expected, (source_name, before, text.count(before), expected)
        text = text.replace(before, after)
    target = out / target_name
    target.write_text(text)
    (out / ('original-' + source_name)).write_bytes(source.read_bytes())
    rows.append({'source': identity(source), 'derived': identity(target),
                 'changes': [{'before': a, 'after': b, 'count': c} for a, b, c in changes]})
(out / 'consumed-derive.py').write_bytes(Path(__file__).read_bytes())
(out / 'derive.json').write_text(json.dumps({
    'kind': 'phase30-final-cpu1-tools', 'complete': True, 'executedGates': False,
    'producer': identity(Path(__file__).resolve()), 'derivations': rows,
    'scope': 'Selected-upstream remains CPU4. Other inherited gates move CPU7 to CPU1; tool roots bound to their original repository paths. Test bodies, expected values, inputs and deadlines unchanged.'
}, indent=2) + '\n')
print(json.dumps({'complete': True, 'executedGates': False, 'out': str(out)}))
