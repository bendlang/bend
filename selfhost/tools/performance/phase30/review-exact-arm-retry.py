#!/usr/bin/env python3
"""Retry five exact-arm prefixes with the immutable corrected attempt07 runtime."""
from pathlib import Path
import ast
import hashlib
import json
import re
import sys

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
SOURCE = ROOT / 'selfhost/build/phase30/transfer-07/editdist/candidate.mjs'
PLAN = ROOT / 'design/phase30/exact-constructor-arms-retry.md'
WRAPPER = HERE / 'prototype-acquire.py'
EXPECTED = '7b0d5eb670693d0940155a1e560da81c9d8b98e07f01376264bccb20ba67361c'


def identity(path):
    raw = path.read_bytes()
    return {'file': str(path.resolve()), 'sha256': hashlib.sha256(raw).hexdigest(), 'bytes': len(raw)}


out = Path(sys.argv[1]).resolve()
assert identity(SOURCE)['sha256'] == EXPECTED
out.mkdir(parents=True, exist_ok=False)
inputs = [identity(p) for p in [SOURCE, Path(str(SOURCE) + '.json'), PLAN, WRAPPER, Path(__file__)]]
source = SOURCE.read_text()
assert 'function matcher1p(name,count,arity,make){return fn(1,exactCode(([x],entered)=>{' in source
assert 'if(!entered)return n?jump(fn(arity,c),p):fn(arity,c);' in source
assert '},true))}' in source
lines = source.splitlines(keepends=True)
rewrites = []
for index, line in enumerate(lines):
    owner = re.match(r'G\["(cell(?:\.f[1-4])?)"\]=fn\(', line)
    if not owner: continue
    matches = list(re.finditer(r'matcher1\("(Dp|Tuple)",\(\)=>fn\((\d+),function\(a\)\{', line))
    assert len(matches) == 1
    found = matches[0]
    tag, arity = found.groups()
    assert int(arity) == {'Dp': 4, 'Tuple': 2}[tag]
    replacement = f'matcher1p("{tag}",{arity},{arity},()=>(0,function(a){{'
    lines[index] = line[:found.start()] + replacement + line[found.end():]
    rewrites.append({'owner': owner[1], 'old': found[0], 'new': replacement})
assert len(rewrites) == 5
candidate = ''.join(lines)
for name, text in [('baseline', source), ('exact', candidate)]:
    (out / (name + '.mjs')).write_text(text)
# Reuse only the maintained pure fixture/oracle functions; never execute the
# old acquisition program or import its historical runtime into this attempt.
tree = ast.parse(WRAPPER.read_text())
selected = [node for node in tree.body if isinstance(node, ast.FunctionDef) and node.name in ['wrap', 'oracle']]
assert len(selected) == 2
namespace = {'json': json}
exec(compile(ast.Module(body=selected, type_ignores=[]), str(WRAPPER), 'exec'), namespace)
for name, text in [('baseline', source), ('exact', candidate)]:
    (out / (name + '-row.mjs')).write_text(namespace['wrap'](text, False))
points = [{'args': [n, seed], 'expected': namespace['oracle'](n, seed)}
          for n in [0, 1, 2, 7, 16, 32, 64] for seed in [0, 1, 17, 0xffffffff]]
(out / 'points.json').write_text(json.dumps(points, indent=2) + '\n')
for name, original in [('derive.py', Path(__file__)), ('plan.md', PLAN), ('row-wrapper-source.py', WRAPPER)]:
    (out / name).write_bytes(original.read_bytes())
outputs = {name: identity(out / (name + '.mjs')) for name in ['baseline', 'exact', 'baseline-row', 'exact-row']}
report = {'kind': 'phase30-corrected-entry-exact-arm-retry', 'complete': True, 'inputs': inputs,
          'outputs': outputs, 'rewrites': rewrites, 'points': identity(out / 'points.json'),
          'unchanged': 'Runtime, calls, projections, arrays and body bytes; only five literal-arm prefixes change.',
          'compilerChanged': False, 'correctness': 'pending', 'measurement': 'pending'}
(out / 'derive.json').write_text(json.dumps(report, indent=2) + '\n')
for protocol in ['screen', 'confirm']:
    point = next(p for p in points if p['args'] == [32, 17])
    config = {'protocol': protocol, 'inputs': [identity(out / 'derive.json'), *inputs],
              'cases': [{'id': 'corrected-exact-edit-row-32', 'point': point,
                         'modules': {name: outputs[name + '-row']['file'] for name in ['baseline', 'exact']}}]}
    (out / (protocol + '.json')).write_text(json.dumps(config, indent=2) + '\n')
assert inputs == [identity(Path(row['file'])) for row in inputs]
print(json.dumps({'complete': True, 'sites': len(rewrites), 'outputs': outputs}))
