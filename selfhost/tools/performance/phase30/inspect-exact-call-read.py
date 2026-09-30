#!/usr/bin/env python3
"""Isolate actual code.call authorization in frozen attempt07 emitted runtimes."""
from pathlib import Path
import hashlib
import json
import sys

ROOT = Path(__file__).resolve().parents[4]
PLAN = ROOT / 'design/phase30/exact-entry-call-read.md'
SOURCES = {
    'helper': (ROOT / 'selfhost/build/phase30/fixture-region-07/candidate.mjs',
               '8e9317debb126b7296b67795e3bca8aba871895b1b8ed15e93458f3c03e271a8', [128, 524800], 128),
    'editdist': (ROOT / 'selfhost/build/phase30/transfer-07/editdist/candidate.mjs',
                 '7b0d5eb670693d0940155a1e560da81c9d8b98e07f01376264bccb20ba67361c', [2, 0], 2065873279),
}
NEW = '''function invokeExact(f,all){
  const code=f.code;
  if(!exactCodes.has(code))return code.call(f.env,all);
  const invoke=code.call,env=f.env;
  if(invoke!==exactCall){
    if(typeof invoke!=="function"){
      const code={call:invoke};
      return code.call(env,all);
    }
    return Reflect.apply(invoke,code,[env,all]);
  }
  const previous=exactEntry;
  exactEntry={code,args:all,used:false};
  try{return Reflect.apply(code,env,[all]);}
  finally{exactEntry=previous;}
}
'''


def identity(p):
    raw = p.read_bytes()
    return {'file': str(p.resolve()), 'sha256': hashlib.sha256(raw).hexdigest(), 'bytes': len(raw)}


out = Path(sys.argv[1]).resolve()
out.mkdir(parents=True, exist_ok=False)
inputs = [identity(PLAN), identity(Path(__file__))]
rows, cases, old_function = [], [], None
for name, (source, expected, args, result) in SOURCES.items():
    assert identity(source)['sha256'] == expected
    text = source.read_text()
    assert text.count('function invokeExact(f,all){') == 1
    start = text.index('function invokeExact(f,all){')
    end = text.index('function force(x){', start)
    old = text[start:end]
    assert old.startswith('function invokeExact(f,all){\n  const code=f.code;\n')
    assert old.count('Object.getPrototypeOf(code)') == 1
    assert old.count('Object.getOwnPropertyDescriptor') == 2
    assert old.count('Object.hasOwn') == 1
    if old_function is not None: assert old == old_function
    old_function = old
    directory = out / name
    directory.mkdir()
    baseline, candidate = directory / 'baseline.mjs', directory / 'actual-call.mjs'
    baseline.write_text(text)
    candidate.write_text(text[:start] + NEW + text[end:])
    inputs.append(identity(source))
    row = {'id': name, 'source': identity(source), 'baseline': identity(baseline), 'candidate': identity(candidate)}
    rows.append(row)
    cases.append({'id': 'actual-call-' + name, 'point': {'args': args, 'expected': result},
                  'modules': {'baseline': str(baseline), 'actual_call': str(candidate)}})
    if name == 'helper':
        (out / 'abi.json').write_text(json.dumps({'baseline': str(baseline), 'candidate': str(candidate), 'skipPrototypeControls': False}, indent=2) + '\n')
report = {'kind': 'phase30-exact-entry-actual-call-read', 'complete': True, 'inputs': inputs, 'variants': rows,
          'oldInvokeExact': old_function, 'newInvokeExact': NEW,
          'unchanged': 'All bytes outside invokeExact; no production runtime/compiler edits.',
          'correctness': 'pending', 'measurement': 'pending'}
(out / 'derive.json').write_text(json.dumps(report, indent=2) + '\n')
(out / 'derive.py').write_bytes(Path(__file__).read_bytes())
(out / 'plan.md').write_bytes(PLAN.read_bytes())
for protocol in ['screen', 'confirm']:
    (out / (protocol + '.json')).write_text(json.dumps({'protocol': protocol, 'inputs': [identity(out / 'derive.json'), *inputs], 'cases': cases}, indent=2) + '\n')
print(json.dumps({'complete': True, 'out': str(out), 'variants': rows}))
