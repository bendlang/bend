#!/usr/bin/env python3
"""Separate private-worker hoisting from fusion into fresh registered callbacks."""
from pathlib import Path
import hashlib
import json
import re
import sys

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
SOURCE = ROOT / 'selfhost/build/phase30/fixture-region-07/candidate.mjs'
PLAN = ROOT / 'design/phase30/registered-worker-entry.md'
EXPECTED = '8e9317debb126b7296b67795e3bca8aba871895b1b8ed15e93458f3c03e271a8'


def identity(path):
    raw = path.read_bytes()
    return {'file': str(path.resolve()), 'sha256': hashlib.sha256(raw).hexdigest(), 'bytes': len(raw)}


def close(text, start):
    masked = re.sub(r'/\*[\s\S]*?\*/|"(?:\\.|[^"\\])*"|\'(?:\\.|[^\'\\])*\'',
                    lambda m: ' ' * len(m[0]), text)
    assert masked[start] == '{'
    depth = 1
    for at in range(start + 1, len(masked)):
        if masked[at] == '{': depth += 1
        elif masked[at] == '}':
            depth -= 1
            if depth == 0: return at
    raise ValueError('Unterminated worker body')


def derive(text):
    marker = 'exactCode(function(a,$entered){/* private Nat loop */'
    assert text.count(marker) == 1
    assert '$lifetime30' not in text
    start = text.index(marker)
    opening = start + len('exactCode(function(a,$entered)')
    end = close(text, opening)
    assert text[end:end + 2] == '})'
    body = text[opening + 1:end]
    assert not re.search(r'\b(this|arguments|eval)\b', body)
    assert body.startswith('/* private Nat loop */let $s0=a[0];')
    owner_start = text.rfind('\nG[', 0, start) + 1
    owner_end = text.index('\n', end)
    owner = text[owner_start:owner_end]
    assert owner.startswith('G["mit"]=scalarCapture("mit",(()=>{')
    anchor = 'const $guards='
    assert owner.count(anchor) == 1
    local_start, local_end = start - owner_start, end + 2 - owner_start
    hoisted_owner = owner[:local_start] + 'exactCode($lifetime30Worker)' + owner[local_end:]
    hoisted_owner = hoisted_owner.replace(anchor, 'const $lifetime30Worker=function(a,$entered){' + body + '};' + anchor, 1)
    hoisted = text[:owner_start] + hoisted_owner + text[owner_end:]

    factory = '(()=>{const $lifetime30Code=(0,function(a){const $entered=$lifetime30Take($lifetime30Code,a);' + body + '});return $lifetime30Register($lifetime30Code);})()'
    fused = text[:start] + factory + text[end + 2:]
    helpers = ('function $lifetime30Register(code){exactCodes.add(code);return code;}\n'
               'function $lifetime30Take(code,a){const entry=exactEntry;'
               'const entered=entry!==null&&entry.code===code&&entry.args===a&&!entry.used;'
               'if(entered)entry.used=true;return entered;}\n')
    assert fused.count('function invokeExact(f,all){') == 1
    fused = fused.replace('function invokeExact(f,all){', helpers + 'function invokeExact(f,all){', 1)
    assert hoisted.count(body) == 1 and fused.count(body) == 1
    return {'baseline': text, 'hoisted': hoisted, 'fused': fused}, {
        'owner': 'mit', 'bodyBytes': len(body.encode()), 'bodySha256': hashlib.sha256(body.encode()).hexdigest(),
        'hoistedChanges': 'Only private body lifetime: definition-local body, fresh exactCode wrapper at every successor arm.',
        'fusedChanges': 'Fresh registered anonymous one-argument ordinary callback consumes exact permission before unchanged body.',
        'fusedPrivateRuntimeHelpers': helpers, 'publicCallbackCached': False,
        'unchanged': ['invokeExact', 'apply', 'entry-token installation and cleanup', 'guards', 'slot reads',
                      'primitive expressions', 'helper dictionary', 'loop', 'generic fallback']}


out = Path(sys.argv[1]).resolve()
assert identity(SOURCE)['sha256'] == EXPECTED
out.mkdir(parents=True, exist_ok=False)
inputs = [identity(p) for p in [SOURCE, PLAN, Path(__file__)]]
variants, proof = derive(SOURCE.read_text())
for name, text in variants.items(): (out / (name + '.mjs')).write_text(text)
for name, original in [('derive.py', Path(__file__)), ('plan.md', PLAN)]:
    (out / name).write_bytes(original.read_bytes())
outputs = {name: identity(out / (name + '.mjs')) for name in variants}
report = {'kind': 'phase30-private-worker-lifetime-and-fresh-entry-fusion', 'complete': True,
          'inputs': inputs, 'outputs': outputs, 'proof': proof, 'compilerChanged': False,
          'productionRuntimeChanged': False, 'correctness': 'pending', 'measurement': 'pending'}
(out / 'derive.json').write_text(json.dumps(report, indent=2) + '\n')
for name in ['hoisted', 'fused']:
    config = {'baseline': outputs['baseline']['file'], 'candidate': outputs[name]['file'],
              'skipPrototypeControls': False, 'derivation': identity(out / 'derive.json')}
    (out / (name + '-abi.json')).write_text(json.dumps(config, indent=2) + '\n')
for protocol in ['screen', 'confirm']:
    config = {'protocol': protocol, 'inputs': [identity(out / 'derive.json'), *inputs],
              'cases': [{'id': 'worker-lifetime-entry', 'point': {'args': [128, 524800], 'expected': 128},
                         'modules': {name: item['file'] for name, item in outputs.items()}}]}
    (out / (protocol + '.json')).write_text(json.dumps(config, indent=2) + '\n')
assert inputs == [identity(Path(item['file'])) for item in inputs]
print(json.dumps({'complete': True, 'outputs': outputs, 'bodyBytes': proof['bodyBytes']}))
