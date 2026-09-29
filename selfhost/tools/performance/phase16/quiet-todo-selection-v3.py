"""Correct the duplicated-reference witness to reach checking, not parsing."""
from pathlib import Path
import json
root = Path(__file__).resolve().parents[4]
phase = root / 'selfhost/build/phase16'
selection = json.loads((phase / 'quiet-todo-selection-02.json').read_text())
out = phase / 'quiet-todo-controls-03'
out.mkdir()
for case in selection['cases']:
    if case['id'] == 'quiet-todo/two-references-one-hole':
        original = Path(case['file']).read_text()
        assert original.count('a + a') == 1
        target = out / 'two-references-one-hole.bend'
        target.write_text(original.replace('a + a', '(a + a : U32)'))
        case['file'] = str(target)
(out / 'selection.json').write_text(json.dumps(selection, indent=2) + '\n')
print(out)
