#!/usr/bin/env python3
"""Account explicitly for the single source edit, unchanged support and research tools."""
import hashlib
import json
import pathlib
import shutil
import sys

root = pathlib.Path(__file__).resolve().parents[4]
out = pathlib.Path(sys.argv[1]).resolve()
out.mkdir()

def identity(file):
    data = file.read_bytes()
    return {'file': str(file), 'sha256': hashlib.sha256(data).hexdigest(), 'bytes': len(data),
            'physical': len(data.decode().splitlines()), 'nonblank': sum(bool(x.strip()) for x in data.decode().splitlines())}

baseline = json.loads((root / 'selfhost/build/phase12/integrated-03/attempt.json').read_text())
candidate = json.loads((root / 'selfhost/build/phase14/dispatch-source-01/checked-01/attempt.json').read_text())
a, b = (pathlib.Path(m['snapshot']['root']) for m in [baseline, candidate])
modules = json.loads((a / 'src/compiler.json').read_text())['modules']
rows = [{'relative': name, 'before': identity(a / name), 'after': identity(b / name)} for name in modules]
assert [row['relative'] for row in rows if row['before']['sha256'] != row['after']['sha256']] == ['src/core/normalize.bend']
support = [{'relative': name, 'before': identity(a / name), 'after': identity(b / name)}
           for name in ['tools/development/equality.mjs', 'tools/development/equality.test.mjs', 'src/runtime.mjs']]
assert all(row['before']['sha256'] == row['after']['sha256'] for row in support)
tools = [identity(p) for p in sorted((root / 'selfhost/tools/performance/phase14').glob('dispatch-*'))]
regression = [identity(root / 'selfhost/tools/performance/phase14' / name)
              for name in ['dispatch-component-v2.mjs', 'dispatch-controls.mjs']]
total = lambda files: {key: sum(row[key] for row in files) for key in ['physical', 'nonblank', 'bytes']}
report = {'kind': 'phase14-dispatch-final-complexity', 'complete': True, 'tool': identity(pathlib.Path(__file__).resolve()),
          'scope': 'All 59 declared modules audited; one source change. Existing helper/tests/runtime unchanged. Runnable paired raw controls need both component builder and control tool, plus existing maintained stage0 tools. Research tools include retained failed versions and this audit.',
          'modules': rows, 'unchangedSupport': support, 'researchTools': tools, 'researchToolTotal': total(tools),
          'pairedRawControlBundle': regression, 'pairedRawControlBundleTotal': total(regression),
          'apis': {label: identity(pathlib.Path(m['api']['file'])) for label, m in [('baseline', baseline), ('candidate', candidate)]}}
shutil.copyfile(__file__, out / 'consumed-tool.py')
(out / 'report.json').write_text(json.dumps(report, indent=2) + '\n')
print(json.dumps({key: report[key] for key in ['researchToolTotal', 'pairedRawControlBundleTotal']}))
