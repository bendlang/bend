#!/usr/bin/env python3
"""Independent16/17 dependency audit for explicitly labelled evidence reuse."""
from pathlib import Path
import hashlib, json, shutil, sys

config_file, out = map(lambda x: Path(x).resolve(), sys.argv[1:])
config = json.loads(config_file.read_text())
out.mkdir(exist_ok=False)
root = Path(__file__).resolve().parents[4]
report = {'kind': 'phase30-registration-flag-evidence-reuse', 'complete': False,
          'pass': False, 'inputs': [], 'snapshotDifferences': [], 'reusedReceipts': [],
          'scope': 'Unchanged executable frontend/native dependencies. IO interpreter explicitly excluded. Original16 acquisition labels and raw outcomes retained; no new fixture executions or JS runtime timing transfer.'}

def ident(file):
    file = Path(file).resolve()
    data = file.read_bytes()
    return {'file': str(file), 'sha256': hashlib.sha256(data).hexdigest(), 'bytes': len(data)}

def save():
    (out / 'report.json').write_text(json.dumps(report, indent=2) + '\n')

def bind(file, expected=None):
    x = ident(file)
    if expected is not None:
        assert x['sha256'] == expected, str(file)
    report['inputs'].append(x)
    return x

def flag_edit(data):
    for old, new in [(b'let exactEntry=null;', b'let exactEntry=null,hasExactCodes=false;'),
                     (b'  exactCodes.add(code);', b'  exactCodes.add(code);\n  hasExactCodes=true;'),
                     (b'  if(!exactCodes.has(code)||', b'  if(!hasExactCodes||!exactCodes.has(code)||')]:
        assert data.count(old) == 1
        data = data.replace(old, new)
    return data

shutil.copyfile(__file__, out / 'consumed-audit.py')
save()
try:
    bind(__file__)
    bind(config_file)
    bind(root / 'design/phase30/registration-flag-independent-validation.md')
    attempts = []
    for key, name in [('before', 'attempt-16'), ('after', 'attempt-17')]:
        directory = Path(config[key]).resolve()
        assert directory.name == name
        bind(directory / 'attempt.json')
        m = json.loads((directory / 'attempt.json').read_text())
        assert m['checked'] is True and m['artifactKind'] == 'derived-b1'
        for artifact in ['api', 'checkedApi', 'base', 'node', 'runtime', 'bootstrapReport', 'derivationReport']:
            bind(m[artifact]['file'], m[artifact]['sha256'])
        mapping = {}
        for row in m['snapshot']['sources']:
            item = row['frozen']
            rel = str(Path(item['file']).relative_to(m['snapshot']['root']))
            assert rel not in mapping
            bind(item['file'], item['sha256'])
            mapping[rel] = item
        boot = json.loads(Path(m['bootstrapReport']['file']).read_text())
        bind(boot['source'], boot['sourceSha256'])
        manifest = Path(m['snapshot']['root']) / 'src/compiler.json'
        bind(manifest)
        attempts.append((m, mapping, boot, manifest))
    (a, am, ab, af), (b, bm, bb, bf) = attempts
    assert a['config'] == b['config'], 'Attempt configuration changed'
    assert am.keys() == bm.keys(), 'Snapshot file set changed'
    for key in ['api', 'checkedApi', 'base', 'node']:
        assert a[key]['sha256'] == b[key]['sha256'], key
    assert ab['sourceSha256'] == bb['sourceSha256']
    assert af.read_bytes() == bf.read_bytes(), 'Ordered compiler manifest changed'
    modules = json.loads(af.read_text())['modules']
    assert len(modules) == 65
    for module in modules:
        assert am[module]['sha256'] == bm[module]['sha256'], module
    runtime_paths = {'src/runtime/js/core.mjs', 'src/runtime.mjs'}
    documentation_paths = {'src/back/js/README.md'}
    for rel in sorted(am):
        if am[rel]['sha256'] == bm[rel]['sha256']:
            continue
        row = {'relative': rel, 'before': am[rel], 'after': bm[rel]}
        report['snapshotDifferences'].append(row)
        save()
        if rel in runtime_paths:
            assert flag_edit(Path(am[rel]['file']).read_bytes()) == Path(bm[rel]['file']).read_bytes(), rel
            row['classification'] = 'exact three selected flag edits'
        else:
            assert rel in documentation_paths, 'Unexpected changed snapshot input: ' + rel
            row['classification'] = 'explicit non-executable documentation path'
    assert runtime_paths.issubset({x['relative'] for x in report['snapshotDifferences']})
    driver = Path(am['tools/typed-driver.mjs']['file']).read_text()
    assert driver.count("fs.readFileSync(runtimePath,'utf8')") == 1
    js_read = driver.index("fs.readFileSync(runtimePath,'utf8')")
    assert driver.index("if(mode==='parse') return") < js_read
    assert driver.index("if(mode==='check') return") < js_read
    assert driver.index("if(mode==='interpreter') {") < js_read
    assert driver.index("if(mode==='native') {") < js_read
    for entry in config['receipts']:
        p = Path(entry['file']).resolve()
        d = json.loads(p.read_text())
        assert d['complete'] is True
        assert d.get('pass') is True or d.get('agreementComplete') is True
        for item in d.get('inputs', []):
            bind(item['file'], item['sha256'])
        if entry['kind'] == 'frontend':
            assert d['api']['sha256'] == a['api']['sha256']
            assert d['exactAgreement'] and d['healthPass']
            assert d['exact'] == d['expected'] and d['differences'] == d['extraFieldDifferences'] == 0
            bind(d['candidate']['file'], d['candidate']['sha256'])
            selected = {'observations': d['exact'], 'scope': d['scope']}
        elif entry['kind'] == 'backend-native-check':
            assert d['kind'] == 'phase30-backend-classification-repair'
            assert d['exactRows'] == 81 and d['counts'] == {'pass': 69, 'not-applicable': 8, 'fail': 4}
            assert d['unexecuted'] == []
            bind(d['plan']['file'], d['plan']['sha256'])
            plan = json.loads(Path(d['plan']['file']).read_text())
            old_manifest = Path(config['before']).resolve() / 'attempt.json'
            assert any(Path(x['file']).resolve() == old_manifest and x['sha256'] == ident(old_manifest)['sha256'] for x in plan['inputs'])
            for item in plan['inputs']:
                bind(item['file'], item['sha256'])
            rows = [row for row in d['rows'] if row['lane'] in ['check', 'native']]
            assert len(rows) == 27 and all(row['exactAgreement'] and row['semanticAgreement'] for row in rows)
            selected = {'observations': len(rows), 'lanes': ['check', 'native'], 'excludedLanes': ['interpreter', 'js'],
                        'rows': rows, 'executionContext': 'Historical16 native retry used the explicitly approved outer execution context.'}
        else:
            raise AssertionError('Unknown reuse scope: ' + entry['kind'])
        report['reusedReceipts'].append({'kind': entry['kind'], 'receipt': bind(p),
            'scope': entry['scope'], 'acquiredOn': 'checked16', 'fresh17Execution': False, 'selected': selected})
    report['unchanged'] = {key: a[key]['sha256'] for key in ['api', 'checkedApi', 'base', 'node']}
    report['unchanged']['assembledSource'] = ab['sourceSha256']
    report['unchanged']['moduleManifest'] = ident(af)['sha256']
    report['moduleCount'] = len(modules)
    report['runtimeBefore'], report['runtimeAfter'] = a['runtime'], b['runtime']
    report['reviewedBranchBoundary'] = 'The sole generated-JS runtime read follows the returning parse/check/native branches; IO interpreter falls through and is excluded. The compiler API itself is unchanged standalone code.'
    for item in report['inputs']:
        assert ident(item['file']) == item, item['file']
    report['complete'] = report['pass'] = True
except BaseException as error:
    report['error'] = repr(error)
finally:
    save()
print(json.dumps({'complete': report['complete'], 'pass': report['pass'], 'differences': len(report['snapshotDifferences']), 'error': report.get('error')}))
raise SystemExit(0 if report['pass'] else 1)
