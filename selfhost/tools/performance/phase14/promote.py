#!/usr/bin/env python3
"""Apply only the validated frozen source/host/selection; release.mjs installs."""
import hashlib, json, pathlib, shutil

root = pathlib.Path(__file__).resolve().parents[4]
out = root / 'selfhost/build/phase14/promotion-01'
out.mkdir()
base = root / 'selfhost/build/phase12/integrated-03/snapshot'
candidate = root / 'selfhost/build/phase14/combined-01/snapshot'
gates = []
for relative in ['combined-01/validation-001/report.json', 'frontend-audit-02/report.json',
                 'backend-01/report.json', 'helper-gates-01/report.json',
                 'dispatch-combined-history-01/report.json', 'check-matrix-01/report.json']:
    p = root / 'selfhost/build/phase14' / relative
    r = json.loads(p.read_text())
    assert r['complete'] and not r.get('error'), relative
    if relative != 'check-matrix-01/report.json':
        assert r['pass'], relative
    gates.append({'file': str(p), 'sha256': hashlib.sha256(p.read_bytes()).hexdigest()})
files = ['src/front/declarations.bend', 'src/front/validate.bend', 'src/load/graph.bend',
         'src/load/modules.bend', 'src/driver/report.bend', 'src/diagnostic/render.bend',
         'src/core/normalize.bend', 'tools/typed-driver.mjs', 'tests/frontend/phase2-rules/cases.json']
changes = []
for relative in files:
    old, live, new = base / relative, root / 'selfhost' / relative, candidate / relative
    assert live.read_bytes() == old.read_bytes(), 'Unexpected live edit: ' + relative
    assert new.read_bytes() != old.read_bytes(), 'Expected candidate change: ' + relative
    changes.append({'file': relative, 'beforeSha256': hashlib.sha256(live.read_bytes()).hexdigest(),
                    'afterSha256': hashlib.sha256(new.read_bytes()).hexdigest()})
for relative in files:
    shutil.copy2(candidate / relative, root / 'selfhost' / relative)
shutil.copy2(__file__, out / 'consumed-tool.py')
(out / 'report.json').write_text(json.dumps({'kind': 'phase14-source-promotion',
    'complete': True, 'pass': True, 'gates': gates, 'changes': changes,
    'scope': 'Validated source, host and 26-case selection copied; checked release installation and installed/relocated smoke gates are separate.'}, indent=2) + '\n')
print(json.dumps({'applied': len(changes), 'report': str(out / 'report.json')}))
