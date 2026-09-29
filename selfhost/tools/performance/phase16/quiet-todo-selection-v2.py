"""External paired fixtures require a prospective outcome contract."""
from pathlib import Path
import json
root = Path(__file__).resolve().parents[4]
phase = root / 'selfhost/build/phase16'
selection = json.loads((phase / 'quiet-todo-source-01/selection.json').read_text())
for case in selection['cases']:
    if 'file' in case:
        case['accept'] = case['id'] == 'quiet-todo/filled-positive'
        if not case['accept']:
            case['rejectPhase'] = 'check'
out = phase / 'quiet-todo-selection-02.json'
with out.open('x') as f:
    f.write(json.dumps(selection, indent=2) + '\n')
print(out)
