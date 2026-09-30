#!/usr/bin/env python3
"""Freeze actual compiler terminal-region timings after semantic controls."""
from pathlib import Path
import hashlib
import json
import sys

ROOT = Path(__file__).resolve().parents[4]
controls, out = map(lambda p: Path(p).resolve(), sys.argv[1:])
out.mkdir(parents=True, exist_ok=False)


def identity(p):
    p = Path(p).resolve()
    raw = p.read_bytes()
    return {'file': str(p), 'sha256': hashlib.sha256(raw).hexdigest(), 'bytes': len(raw)}


assert json.loads((controls / 'report.json').read_text())['pass']
inputs = [identity(Path(__file__)), identity(controls / 'report.json'),
          identity(controls / 'derive.json')]
whole, chunks = {}, {}
marker = 'export default Object.fromEntries(Object.keys(G).map(k=>[k,(...args)=>call(get(G,k),args)]));'
wrapper = '''const $terminalExports=Object.fromEntries(Object.keys(G).map(k=>[k,(...args)=>call(get(G,k),args)]));
export default {...$terminalExports,chunkBench:(pixels,index)=>{
 const result=$terminalExports.hchunk(BigInt(pixels),index,7n,0,0,0,0,0,0,0,0);
 let checksum=0;for(const field of result.a)checksum=(Math.imul(checksum,2654435761)+field)>>>0;
 return checksum;
}};'''
for variant in ['baseline', 'candidate']:
    module = controls / (variant + '.mjs')
    text = module.read_text()
    assert text.count(marker) == 1
    target = out / (variant + '-chunk.mjs')
    target.write_text(text.replace(marker, wrapper))
    inputs.extend([identity(module), identity(target)])
    whole[variant], chunks[variant] = str(module), str(target)
upstream = ROOT / 'selfhost/build/phase28/runtime-01/mandelbrot/upstream.mjs'
inputs.append(identity(upstream))
whole['typescript'] = str(upstream)
checksum = 0
for value in [0, 64, 0, 0, 0, 0, 0, 0]:
    checksum = (checksum * 2654435761 + value) & 0xffffffff
cases = [
    {'id': 'actual-terminal-original-mandelbrot',
     'point': {'args': [2, 0], 'expected': 887240761}, 'modules': whole},
    {'id': 'actual-terminal-chunk64',
     'point': {'exportName': 'chunkBench', 'args': [64, 0], 'expected': checksum},
     'modules': chunks},
]
plan = {'complete': True, 'inputs': inputs, 'cases': cases,
        'scope': 'Actual checked08 versus09. Same original bench and complete chunk checksum as the prototype. Public runtime unchanged; no instrumented modules.'}
(out / 'plan.json').write_text(json.dumps(plan, indent=2) + '\n')
for protocol in ['screen', 'confirm']:
    config = {'protocol': protocol, 'inputs': [identity(out / 'plan.json'), *inputs],
              'cases': cases}
    (out / (protocol + '.json')).write_text(json.dumps(config, indent=2) + '\n')
assert all(identity(item['file']) == item for item in inputs)
print(json.dumps({'complete': True, 'out': str(out)}))
