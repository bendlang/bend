from pathlib import Path
import hashlib, json, shutil

root = Path(__file__).resolve().parents[4]
phase = root / 'selfhost/build/phase16'
prior = phase / 'literal-context-source-03'
base = phase / 'wave9-source-01/project'
namespace = phase / 'spans-context-namespace-source-01'
out = phase / 'literal-context-source-04'
f = 'src/front/declarations.bend'
assert (prior / 'project' / f).read_bytes() == (base / f).read_bytes()
actual = {str(p.relative_to(base)) for folder in ['src', 'tools', 'tests'] for p in (base / folder).rglob('*') if p.is_file() and p.read_bytes() != (namespace / 'project' / p.relative_to(base)).read_bytes()}
assert actual == {f}, actual
out.mkdir()
shutil.copytree(prior / 'project', out / 'project')
shutil.copy2(namespace / 'project' / f, out / 'project' / f)
shutil.copy2(__file__, out / 'consumed-tool.py')
def ident(p):
    return {'file': str(p.resolve()), 'sha256': hashlib.sha256(p.read_bytes()).hexdigest()}
(out / 'manifest.json').write_text(json.dumps({'complete': True, 'pass': True, 'parent': str(prior / 'project'), 'plan': ident(root / 'design/phase16/literal-context-integration.md'), 'tool': ident(Path(__file__)), 'inputs': [ident(prior / 'manifest.json'), ident(namespace / 'manifest.json')], 'changes': [{'path': f, 'before': ident(prior / 'project' / f), 'after': ident(out / 'project' / f)}], 'installationEligible': False}, indent=2) + '\n')
(out / 'workflow.json').write_text(json.dumps({'project': str(out / 'project'), 'upstream': str(root / 'selfhost/.bootstrap/upstream-phase8'), 'profile': 'equality', 'cpu': '0', 'jobs': 1}, indent=2) + '\n')
print(out)
