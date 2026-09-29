from pathlib import Path
import hashlib, json, shutil

root = Path(__file__).resolve().parents[4]
phase = root / 'selfhost/build/phase16'
out = phase / 'program-completion-controls-01'
out.mkdir()
cases = json.loads((phase / 'quiet-todo-controls-03/selection.json').read_text())['cases']
cases.append({'id': 'check/axiom_runtime_capture.bend', 'lanes': ['check']})
app = 'def app(~f: Nat -> Nat, x: Nat) -> Nat:\n  f(x)\n'
fixtures = {
    'hole-before-invalid-instance': app + 'def hole() -> Nat:\n  ?\ndef main() -> Nat:\n  app(~(n => Nat.add(n, n)), 1n)\n',
    'hole-after-invalid-instance': app + 'def main() -> Nat:\n  app(~(n => Nat.add(n, n)), 1n)\ndef hole() -> Nat:\n  ?\n',
    'hole-valid-instance': app + 'def hole() -> Nat:\n  ?\ndef main() -> Nat:\n  app(~(n => n), 1n)\n',
    'open-law-valid-instance': app + 'law pending:\n  Nat\ndef main() -> Nat:\n  app(~(n => n), 1n)\n',
    'hole-repeated-instance': 'def value(~T: Type) -> Nat:\n  ?\ndef main() -> Nat:\n  Nat.add(value(~Nat), value(~Nat))\n',
    'valid-instance': app + 'def main() -> Nat:\n  app(~(n => n), 1n)\n',
    'same-body-known-gap': app + 'def main() -> Nat:\n  y = app(~(n => Nat.add(n, n)), 1n)\n  True{}\n',
    'ordinary-before-instance': app + 'def main() -> Nat:\n  y: Nat = True{}\n  app(~(n => Nat.add(n, n)), y)\n',
}
for name, body in fixtures.items():
    file = out / (name + '.bend')
    file.write_text('import Base\n' + body)
    case = {'id': 'program-completion/' + name, 'file': str(file), 'lanes': ['check'], 'accept': name == 'valid-instance'}
    if not case['accept']:
        case['rejectPhase'] = 'check'
    cases.append(case)
(out / 'selection.json').write_text(json.dumps({'cases': cases}, indent=2) + '\n')
def ident(p):
    return {'file': str(p.resolve()), 'sha256': hashlib.sha256(p.read_bytes()).hexdigest()}
(out / 'manifest.json').write_text(json.dumps({'plan': ident(root / 'design/phase16/program-completion.md'), 'tool': ident(Path(__file__)), 'inputs': [ident(phase / 'quiet-todo-controls-03/selection.json')], 'fixtures': [ident(p) for p in sorted(out.glob('*.bend'))]}, indent=2) + '\n')
shutil.copy2(__file__, out / 'consumed-tool.py')
print(out)
