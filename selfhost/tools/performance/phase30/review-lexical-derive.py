#!/usr/bin/env python3
"""Freeze a spelling-only dictionary-to-lexical private-helper ablation."""
from pathlib import Path
import hashlib
import json
import re
import sys

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
SOURCE = ROOT / 'selfhost/build/phase30/fixture-region-07/candidate.mjs'
PLAN = ROOT / 'design/phase30/lexical-private-helpers.md'
EXPECTED = '8e9317debb126b7296b67795e3bca8aba871895b1b8ed15e93458f3c03e271a8'


def identity(path):
    raw = path.read_bytes()
    return {'file': str(path.resolve()), 'sha256': hashlib.sha256(raw).hexdigest(),
            'bytes': len(raw)}


def masked(text):
    return re.sub(r'/\*[\s\S]*?\*/|"(?:\\.|[^"\\])*"|\'(?:\\.|[^\'\\])*\'',
                  lambda m: ' ' * len(m[0]), text)


def closing_brace(text, start):
    source = masked(text)
    assert source[start] == '{'
    depth = 1
    for pos in range(start + 1, len(source)):
        if source[pos] == '{':
            depth += 1
        elif source[pos] == '}':
            depth -= 1
            if depth == 0:
                return pos
    raise ValueError('Unterminated private helper body')


def derive(source):
    assert source.count('const $R=Object.create(null);') == 1
    assert '$lexical30_' not in source
    region_start = source.index('const $R=Object.create(null);')
    region_end = source.index('const $guards=', region_start)
    owner_start = source.rfind('G[', 0, region_start)
    owner_end = source.index('\n', region_end)
    assert source[owner_start:].startswith('G["mit"]=scalarCapture("mit",(()=>{')
    declarations = source[region_start:region_end]
    remainder = declarations[len('const $R=Object.create(null);'):]
    functions = []
    while remainder:
        match = re.match(r'\$R\[("[^"\\]+")\]=function\(([^)]*)\)\{', remainder)
        assert match, 'Unexpected private helper declaration'
        end = closing_brace(remainder, match.end() - 1)
        assert remainder[end + 1] == ';'
        functions.append({'name': json.loads(match[1]), 'params': match[2],
                          'body': remainder[match.end():end],
                          'original': remainder[:end + 2]})
        remainder = remainder[end + 2:]
    assert [f['name'] for f in functions] == ['b2u', 'asr8', 'sel', 'sel.go']
    bindings = {f['name']: '$lexical30_' + str(i) for i, f in enumerate(functions)}
    occurrences = {name: 0 for name in bindings}

    def rewrite(text):
        def replacement(match):
            name = json.loads(match[1])
            assert name in bindings, 'Unknown private helper reference'
            occurrences[name] += 1
            return bindings[name]
        changed = re.sub(r'\$R\[("[^"\\]+")\]', replacement, text)
        assert not re.search(r'(?<![\w$])\$R(?![\w$])', changed)
        return changed

    lexical = ''.join('function ' + bindings[f['name']] + '(' + f['params'] + '){' +
                      rewrite(f['body']) + '}' for f in functions)
    old_suffix = source[region_end:owner_end]
    new_suffix = rewrite(old_suffix)
    candidate = source[:region_start] + lexical + new_suffix + source[owner_end:]
    assert not re.search(r'(?<![\w$])\$R(?![\w$])', candidate)
    assert source[:region_start] == candidate[:region_start]
    assert candidate.endswith(source[owner_end:])
    return candidate, {'owner': 'mit', 'bindings': bindings,
                       'rewrittenReferences': occurrences,
                       'originalDeclaration': declarations,
                       'replacementDeclaration': lexical,
                       'scope': 'Only private helper declarations and their references inside the same owner IIFE.'}


out = Path(sys.argv[1]).resolve()
assert identity(SOURCE)['sha256'] == EXPECTED, 'Frozen source changed'
out.mkdir(parents=True, exist_ok=False)
inputs = [identity(p) for p in [SOURCE, PLAN, Path(__file__)]]
source = SOURCE.read_text()
candidate, proof = derive(source)
(out / 'baseline.mjs').write_text(source)
(out / 'lexical.mjs').write_text(candidate)
(out / 'plan.md').write_bytes(PLAN.read_bytes())
(out / 'derive.py').write_bytes(Path(__file__).read_bytes())
outputs = {name: identity(out / (name + '.mjs')) for name in ['baseline', 'lexical']}
report = {'kind': 'phase30-private-helper-lexical-spelling', 'complete': True,
          'inputs': inputs, 'outputs': outputs, 'proof': proof,
          'compilerChanged': False, 'runtimeChanged': False,
          'correctness': 'pending', 'measurement': 'pending'}
(out / 'derive.json').write_text(json.dumps(report, indent=2) + '\n')
for protocol in ['screen', 'confirm']:
    config = {'protocol': protocol, 'inputs': [identity(out / 'derive.json'), *inputs],
              'cases': [{'id': 'lexical-private-helpers',
                         'point': {'args': [128, 524800], 'expected': 128},
                         'modules': {name: item['file'] for name, item in outputs.items()}}]}
    (out / (protocol + '.json')).write_text(json.dumps(config, indent=2) + '\n')
for label, tool in [('ordinary', 'review-scalar-compiler-run.mjs'),
                    ('entry', 'review-scalar-entry.mjs')]:
    config = {'baseline': outputs['baseline']['file'], 'candidate': outputs['lexical']['file'],
              'skipPrototypeControls': True, 'derivation': identity(out / 'derive.json'),
              'controlTool': identity(HERE / tool)}
    (out / (label + '.json')).write_text(json.dumps(config, indent=2) + '\n')
assert inputs == [identity(Path(item['file'])) for item in inputs]
print(json.dumps({'complete': True, 'out': str(out), 'outputs': outputs,
                  'rewrittenReferences': proof['rewrittenReferences']}))
