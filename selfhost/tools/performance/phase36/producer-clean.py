#!/usr/bin/env python3
"""Derive counter-free timing modules from frozen saved-output controls modules.

This tool only reads and writes files. It never imports emitted JavaScript,
executes programs, builds the compiler, profiles or times anything.
"""
import argparse
import hashlib
import json
from pathlib import Path
import shutil


def identity(file):
    file = Path(file).resolve(strict=True)
    return dict(path=str(file), sha256=hashlib.sha256(file.read_bytes()).hexdigest())


def save(file, value):
    with Path(file).open('x') as stream:
        json.dump(value, stream, indent=2)
        stream.write('\n')


parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('derived', type=Path)
parser.add_argument('typescript', type=Path)
parser.add_argument('out', type=Path)
args = parser.parse_args()
source = args.derived.resolve(strict=True)
typescript = args.typescript.resolve(strict=True)
out = args.out.resolve()
assert not out.exists(), 'output directory must be new'
manifest_file = source/'derive.json'
manifest = json.loads(manifest_file.read_text())
assert manifest['kind'] == 'phase36-private-producer-prototype' and manifest['complete']
assert manifest['parent']['sha256'] == 'dd400df33dc3acbf50c781778a85eb8960bdd065d40a5bf6cffde0009bb3ad26'
inputs = [identity(__file__), identity(manifest_file), identity(typescript)]
rows = []
for variant in ['baseline', 'generator', 'producer']:
    parent = source/(variant+'.mjs')
    ident = identity(parent)
    stored = next(x for x in manifest['modules'] if x['variant'] == variant)
    assert ident['sha256'] == stored['sha256'], 'frozen input mismatch: '+variant
    inputs.append(ident)
    original = parent.read_text()
    text = original
    changes = [('export function producerEntryCount(){return 0;}\n', '')] if variant == 'baseline' else [
        ('let $producerEntries=0;\n', ''),
        ('function $producerGen(d,h){++$producerEntries;', 'function $producerGen(d,h){'),
        ('export function producerEntryCount(){return $producerEntries;}\n', ''),
    ]
    for before, after in changes:
        assert text.count(before) == 1, (variant, before, 'one counter construct required')
        text = text.replace(before, after, 1)
    assert '$producerEntries' not in text and 'producerEntryCount' not in text
    # Reversing just the recorded edits must reproduce every original byte.
    rebuilt = text
    for before, after in reversed(changes):
        if after:
            assert rebuilt.count(after) == 1
            rebuilt = rebuilt.replace(after, before, 1)
        # Empty replacement locations are recorded as exact byte diffs below;
        # deletion replay, rather than searching an empty string, verifies them.
    cursor = 0
    spans = []
    for before, after in changes:
        start = original.index(before)
        spans.append(dict(start=start, end=start+len(before), before=before, after=after))
    replay = original
    for change in sorted(spans, key=lambda x:x['start'], reverse=True):
        replay = replay[:change['start']]+change['after']+replay[change['end']:]
    assert replay == text, 'edits must contain only recorded counter constructs'
    rows.append((variant, ident, text, spans))

out.mkdir(parents=True)
shutil.copyfile(__file__, out/'consumed-clean.py')
shutil.copyfile(manifest_file, out/'parent-derive.json')
report = dict(kind='phase36-counter-free-producer-timing-modules', complete=False,
              inputs=inputs, modules=[],
              scope='Removes only diagnostic counter declaration, increment and entry-count export. Producer/cand bodies, guards, diagnostic non-counter exports and benchmark inputs are otherwise byte-identical. No execution or timing performed.')
for variant, parent, text, spans in rows:
    destination = out/(variant+'.mjs')
    destination.write_text(text)
    report['modules'].append(dict(variant=variant, parent=parent, output=identity(destination),
                                  bytes=len(text.encode()), edits=spans))
for item in inputs:
    assert identity(item['path']) == item
report['complete'] = True
save(out/'derive.json', report)
config = dict(inputs=[str(out/'derive.json'), *[row['path'] for row in inputs]], cases=[dict(
    id='symreg', point=dict(exportName='bench', args=[6, 42], expected=2490246820),
    modules={**{v:str(out/(v+'.mjs')) for v in ['baseline','generator','producer']}, 'typescript':str(typescript)})])
save(out/'compare.json', config)
print(json.dumps(dict(complete=True, out=str(out), config=str(out/'compare.json'), modules=report['modules'])))
