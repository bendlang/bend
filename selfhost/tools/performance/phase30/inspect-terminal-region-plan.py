#!/usr/bin/env python3
"""Freeze original-program and complete-chunk timing configurations, without running them."""
import hashlib
import json
import shutil
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[4]
source, out = map(lambda p: Path(p).resolve(), sys.argv[1:])
out.mkdir(parents=True, exist_ok=False)


def identity(p):
    p = Path(p).resolve()
    raw = p.read_bytes()
    return {'file': str(p), 'sha256': hashlib.sha256(raw).hexdigest(), 'bytes': len(raw)}


inputs = [identity(Path(__file__)), identity(source / 'derive.json')]
for p in [ROOT / 'selfhost/build/phase30/inspection-terminal-controls-02/report.json',
          ROOT / 'selfhost/build/phase30/inspection-terminal-counts-02/report.json']:
    assert json.loads(p.read_text())['pass']
    inputs.append(identity(p))
variants = ['baseline', 'outer', 'acyclic', 'nested']
whole, chunks = {}, {}
marker = 'export default Object.fromEntries(Object.keys(G).map(k=>[k,(...args)=>call(get(G,k),args)]));'
wrapper = '''const $inspectionExports=Object.fromEntries(Object.keys(G).map(k=>[k,(...args)=>call(get(G,k),args)]));
export default {...$inspectionExports,chunkBench:(pixels,index)=>{
 const result=$inspectionExports.hchunk(BigInt(pixels),index,7n,0,0,0,0,0,0,0,0);
 let checksum=0;for(const field of result.a)checksum=(Math.imul(checksum,2654435761)+field)>>>0;
 return checksum;
}};'''
for variant in variants:
    original = source / (variant + '.mjs')
    inputs.append(identity(original))
    target = out / (variant + '-chunk.mjs')
    text = original.read_text()
    assert text.count(marker) == 1
    target.write_text(text.replace(marker, wrapper))
    whole[variant] = str(original)
    chunks[variant] = str(target)
upstream = ROOT / 'selfhost/build/phase28/runtime-01/mandelbrot/upstream.mjs'
inputs.append(identity(upstream))
whole['typescript'] = str(upstream)
checksum = 0
for x in [0, 64, 0, 0, 0, 0, 0, 0]: checksum = (checksum * 2654435761 + x) & 0xffffffff
plan = {'kind': 'phase30-terminal-region-prospective-timing', 'complete': True,
        'inputs': inputs, 'derivedChunks': [identity(p) for p in chunks.values()],
        'scope': 'Unchanged original small bench(2,0), plus complete first-pass chunk64 with the same fixed7 inner iterations and a full8field checksum. Standard clean screen/long-warm confirmation. Chunk wrappers are identical; instrumented modules excluded.',
        'cases': [{'id': 'original-mandelbrot-small', 'point': {'args': [2, 0], 'expected': 887240761}, 'modules': whole},
                  {'id': 'terminal-chunk64', 'point': {'exportName': 'chunkBench', 'args': [64, 0], 'expected': checksum}, 'modules': chunks}]}
shutil.copyfile(Path(__file__), out / 'consumed-plan.py')
(out / 'plan.json').write_text(json.dumps(plan, indent=2) + '\n')
for protocol in ['screen', 'confirm']:
    (out / (protocol + '.json')).write_text(json.dumps({'protocol': protocol, 'inputs': [identity(out / 'plan.json'), *inputs], 'cases': plan['cases']}, indent=2) + '\n')
print(json.dumps({'complete': True, 'out': str(out), 'cases': [c['id'] for c in plan['cases']], 'chunkExpected': checksum}))
