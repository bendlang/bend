#!/usr/bin/env python3
"""Compose named, immutable source changes into a fresh checked-workflow project."""
import difflib
import hashlib
import json
from pathlib import Path
import shutil
import sys

root = Path(__file__).resolve().parents[4]
config_file = Path(sys.argv[1]).resolve()
config = json.loads(config_file.read_text())
out = Path(sys.argv[2]).resolve()
out.mkdir()
base = root / 'selfhost/build/phase15/combined-02/snapshot'


def identity(p):
    return {'file': str(p), 'canonicalPath': str(p.resolve()),
            'sha256': hashlib.sha256(p.read_bytes()).hexdigest(),
            'bytes': p.stat().st_size}


def write(p, data):
    p.write_text(json.dumps(data, indent=2) + '\n')


# Reject partial owner compositions before copying or running any compiler.
for owner in config['owners']:
    source = Path(owner['source']).resolve()
    requested = {x['relative'] for x in owner['files']}
    actual = set()
    for subtree in ['src', 'tools']:
        for file in (source / subtree).rglob('*'):
            if file.is_file():
                name = str(file.relative_to(source))
                previous = base / name
                if not previous.exists() or file.read_bytes() != previous.read_bytes():
                    actual.add(name)
    if actual != requested:
        raise ValueError('Owner source manifest is incomplete: ' + owner['name'] +
                         '; omitted=' + str(sorted(actual - requested)) +
                         '; unchanged=' + str(sorted(requested - actual)))

project = out / 'project'
for name in ['src', 'tools', 'tests']:
    shutil.copytree(base / name, project / name)
(project / 'dist').mkdir()
report = {'kind': 'phase16-combined-source-preparation', 'complete': False,
          'tool': identity(Path(__file__).resolve()), 'config': identity(config_file),
          'baselineAttempt': identity(base.parent / 'attempt.json'), 'changes': []}
seen = set()
for owner in config['owners']:
    source = Path(owner['source']).resolve()
    for item in owner['files']:
        name = item['relative']
        if name in seen or name.startswith('/') or '..' in Path(name).parts:
            raise ValueError('Overlapping or unsafe source path: ' + name)
        seen.add(name)
        before, after = base / name, source / name
        if identity(after)['sha256'] != item['sha256']:
            raise ValueError('Changed owner source: ' + str(after))
        if before.read_bytes() == after.read_bytes():
            raise ValueError('No source change: ' + name)
        patch = out / (name.replace('/', '_') + '.patch')
        patch.write_text(''.join(difflib.unified_diff(before.read_text().splitlines(True),
            after.read_text().splitlines(True), fromfile='a/selfhost/' + name,
            tofile='b/selfhost/' + name)))
        shutil.copy2(after, project / name)
        report['changes'].append({'owner': owner['name'], 'relative': name,
            'before': identity(before), 'after': identity(after), 'patch': identity(patch),
            'composed': identity(project / name)})
workflow = out / 'workflow.json'
write(workflow, {'project': str(project),
                'upstream': str(root / 'selfhost/.bootstrap/upstream-phase8'),
                'profile': 'equality', 'cpu': str(config.get('cpu', '0')), 'jobs': 1})
report['workflow'] = identity(workflow)
report['complete'] = True
write(out / 'manifest.json', report)
shutil.copy2(__file__, out / 'consumed-tool.py')
print(out)
