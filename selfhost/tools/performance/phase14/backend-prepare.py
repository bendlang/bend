#!/usr/bin/env python3
import hashlib, json, pathlib, shutil
root = pathlib.Path(__file__).resolve().parents[4]
out = root / 'selfhost/build/phase14/backend-inputs-01'
out.mkdir()
old = root / 'selfhost/build/phase12/backend-04/selection.json'
source = root / 'selfhost/build/phase14/laws-controls-04/fixtures/safe-renamed-dependent.bend'
cases = json.loads(old.read_text())['cases']
cases.append({'id': 'p14/imported-dependent-fill', 'file': str(source),
              'lanes': ['check', 'interpreter', 'js', 'native'], 'expected': '5n'})
selection = out / 'selection.json'
selection.write_text(json.dumps({'cases': cases}, indent=2) + '\n')
shutil.copy2(__file__, out / 'consumed-tool.py')
(out / 'plan.json').write_text(json.dumps({'kind': 'phase14-backend-gate-plan',
    'inputs': [{'file': str(p), 'sha256': hashlib.sha256(p.read_bytes()).hexdigest()}
               for p in [pathlib.Path(__file__).resolve(), old, source]],
    'scope': 'Preserve 37 Phase12 paired rows and three known exact differences; add four lanes for a renamed dependent imported-law fill returning 5n. TypeScript and candidate must agree on the exact new output. Clang16 compiles and runs native output.'}, indent=2) + '\n')
