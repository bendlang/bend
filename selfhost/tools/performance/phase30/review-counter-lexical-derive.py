#!/usr/bin/env python3
"""Frozen Number-countdown-only ablation on checked lexical helper output."""
from pathlib import Path
import hashlib
import json
import re
import sys

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
SOURCE = ROOT / 'selfhost/build/phase30/fixture-region-08/candidate.mjs'
RECEIPT = SOURCE.with_suffix('.mjs.json')
PLAN = ROOT / 'design/phase30/private-counter-lexical-retry.md'
EXPECTED = 'fa9cc6361f7d11e5e340d487f0ac918fd51212b82611b2a8baf247c847787da3'


def identity(path):
    raw = path.read_bytes()
    return {'file': str(path.resolve()), 'sha256': hashlib.sha256(raw).hexdigest(),
            'bytes': len(raw)}


def closing_brace(text, start):
    masked = re.sub(r'/\*[\s\S]*?\*/|"(?:\\.|[^"\\])*"|\'(?:\\.|[^\'\\])*\'',
                    lambda match: ' ' * len(match[0]), text)
    assert masked[start] == '{'
    depth = 1
    for pos in range(start + 1, len(masked)):
        if masked[pos] == '{':
            depth += 1
        elif masked[pos] == '}':
            depth -= 1
            if depth == 0:
                return pos
    raise ValueError('Unclosed JavaScript body')


def locate(source):
    marker = '/* private scalar region */'
    assert source.count(marker) == 1
    start = source.index(marker) + len(marker)
    conversion = '$s0=Number($s0);' if source.startswith('$s0=Number($s0);', start) else ''
    loop_start = start + len(conversion)
    assert source.startswith('for(;;){', loop_start)
    loop_end = closing_brace(source, loop_start + len('for(;;)')) + 1
    callback = 'function(a,$entered){/* private Nat loop */'
    assert source.count(callback) == 1
    callback_start = source.index(callback) + len('function(a,$entered)')
    callback_end = closing_brace(source, callback_start)
    # Exactly one guard closes between the loop and its original fallback.
    assert source[loop_end] == '}'
    return start, loop_start, loop_end, callback_end, conversion


def derive(source):
    start, loop_start, loop_end, callback_end, conversion = locate(source)
    assert not conversion
    body = source[loop_start:loop_end]
    match = re.match(r'for\(;;\)\{const (x\d+)=\$s0;', body)
    assert match
    alias = match[1]
    assert len(re.findall(r'\b' + alias + r'\b', body)) == 2
    assert body.count('const $n0=' + alias + ';') == 1
    assert len(re.findall(r'(?<![\w$])\$n0\b', body)) == 3
    assert len(re.findall(r'(?<![\w$])\$s0\b', body)) == 2
    assert body.count('if($n0===0n)') == 1
    assert body.count('$s0=$n0-1n;') == 1
    assert '(typeof $s0==="bigint"&&$s0>=0n&&$s0<281474976710655n)' in source[:start]
    assert '$entered&&' in source[:start] and 'scalarGuard($guards)' in source[:start]
    assert 'const $R=Object.create(null);' not in source
    changed = body.replace('if($n0===0n)', 'if($n0===0)').replace('$s0=$n0-1n;', '$s0=$n0-1;')
    result = source[:start] + '$s0=Number($s0);' + changed + source[loop_end:]
    assert result[:start] == source[:start]
    assert result.endswith(source[loop_end:])
    return result, {'predecessorAlias': alias, 'aliasUses': 2, 'nextCounterUses': 3,
                    'stateCounterUses': 2, 'loopBytes': len(body.encode()),
                    'oldLoop': body, 'newLoop': changed,
                    'changes': ['guarded initial Number conversion', 'private zero comparison',
                                'private predecessor subtraction'],
                    'callbackEnd': callback_end}


def diagnostic(source):
    _, loop_start, loop_end, callback_end, conversion = locate(source)
    body = source[loop_start:loop_end]
    alias = re.match(r'for\(;;\)\{const (x\d+)=\$s0;', body)[1]
    zero = re.search(r'if\((\$n0===0n?)\)', body)[1]
    decrement = re.search(r'\$s0=(\$n0-1n?);', body)[1]
    # Retain the actual post-guard conversion. This diagnostic replaces only
    # the already-guarded loop and the cold expression, never an entry check.
    probe = ('const ' + alias + '=$s0;const $n0=' + alias + ';'
             'return {phase:"private",counterType:typeof $n0,counter:String($n0),'
             'zero:' + zero + ',next:String(' + zero + '?$n0:' + decrement + ')};')
    fallback = 'return {phase:"fallback",counterType:typeof $s0};'
    result = source[:loop_start] + probe + '}' + fallback + source[callback_end:]
    assert result.count('scalarGuard($guards)') == source.count('scalarGuard($guards)')
    return result, {'conversionPreserved': bool(conversion), 'zero': zero,
                    'decrement': decrement, 'scope': 'entry sentinel only; never timed'}


out = Path(sys.argv[1]).resolve()
assert identity(SOURCE)['sha256'] == EXPECTED, 'Frozen checked helper changed'
receipt = json.loads(RECEIPT.read_text())
assert receipt['complete'] and receipt['observation']['checked']
assert receipt['output']['sha256'] == EXPECTED
assert identity(Path(receipt['attempt']['file']))['sha256'] == receipt['attempt']['sha256']
out.mkdir(parents=True, exist_ok=False)
inputs = [identity(p) for p in [SOURCE, RECEIPT, PLAN, Path(__file__),
                               Path(receipt['attempt']['file'])]]
source = SOURCE.read_text()
number, proof = derive(source)
diagnostic_proofs = {}
for name, text in [('baseline', source), ('number', number)]:
    (out / (name + '.mjs')).write_text(text)
    probe, probe_proof = diagnostic(text)
    (out / (name + '-diagnostic.mjs')).write_text(probe)
    diagnostic_proofs[name] = probe_proof
for name, path in [('plan.md', PLAN), ('derive.py', Path(__file__)),
                   ('checked-emission.json', RECEIPT)]:
    (out / name).write_bytes(path.read_bytes())
outputs = {name: identity(out / (name + '.mjs'))
           for name in ['baseline', 'number', 'baseline-diagnostic', 'number-diagnostic']}
report = {'kind': 'phase30-lexical-countdown-representation', 'complete': True,
          'inputs': inputs, 'outputs': outputs, 'proof': proof,
          'diagnosticProofs': diagnostic_proofs, 'compilerChanged': False,
          'runtimeChanged': False, 'correctness': 'pending', 'measurement': 'pending'}
(out / 'derive.json').write_text(json.dumps(report, indent=2) + '\n')
for protocol in ['screen', 'confirm']:
    config = {'protocol': protocol, 'inputs': [identity(out / 'derive.json'), *inputs],
              'cases': [{'id': 'lexical-private-number-countdown',
                         'point': {'args': [128, 524800], 'expected': 128},
                         'modules': {name: outputs[name]['file'] for name in ['baseline', 'number']}}]}
    (out / (protocol + '.json')).write_text(json.dumps(config, indent=2) + '\n')
for label, tool in [('abi', 'review-scalar-compiler-run.mjs'),
                    ('entry', 'review-scalar-entry.mjs')]:
    config = {'baseline': outputs['baseline']['file'], 'candidate': outputs['number']['file'],
              'skipPrototypeControls': False, 'derivation': identity(out / 'derive.json'),
              'controlTool': identity(HERE / tool)}
    (out / (label + '.json')).write_text(json.dumps(config, indent=2) + '\n')
assert inputs == [identity(Path(item['file'])) for item in inputs]
print(json.dumps({'complete': True, 'out': str(out), 'outputs': outputs,
                  'changes': proof['changes']}))
