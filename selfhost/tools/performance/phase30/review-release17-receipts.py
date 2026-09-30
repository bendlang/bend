#!/usr/bin/env python3
"""Receipt/file-only final release review; never launches compiler or tests."""
from pathlib import Path
import hashlib, json, shutil, sys

root = Path(__file__).resolve().parents[4]
project = root / 'selfhost'
build = project / 'build/phase30'
out = Path(sys.argv[1]).resolve()
out.mkdir(exist_ok=False)
API = '33545640e25beffb61639b27f4815aaeb345fda14758e1d63418cd1d0ccc0637'
PARENT = '60aa968ffcedb7a02a220b58a51396dd036d0d8b1f39f1b3def3f6b4248d6469'
RUNTIME = '6731308bcddc6faf68d0f2f9988b1299d4d62069fa091e94857f56bded44b3d6'
BASE = 'c742fae9c49b14f0cc9128429a2c6109364c8a933a142f2c90b9f2e5fd976661'
SOURCE = '678bafd61cff715c3ee2012ef3840ddfe99a2aeb1d81b5345fb3c6e6bfc1757e'
PRIOR = '10510efda268bac1f31cc8fed87a9315e8f9edfa15aad6b90b0d96756c217b11'
report = {'kind': 'phase30-independent-installed17-receipt-review', 'complete': False,
          'pass': False, 'inputs': [], 'scope': 'Read/hash existing receipts and artifacts only. No compiler, verifier, fixture, benchmark or smoke command executed.'}

def ident(file):
    file = Path(file).resolve()
    data = file.read_bytes()
    return {'file': str(file), 'sha256': hashlib.sha256(data).hexdigest(), 'bytes': len(data)}

def bind(file, expected=None):
    x = ident(file)
    if expected is not None:
        assert x['sha256'] == expected, str(file)
    report['inputs'].append(x)
    return x

def save():
    (out / 'report.json').write_text(json.dumps(report, indent=2) + '\n')

shutil.copyfile(__file__, out / 'consumed-review.py')
save()
try:
    bind(__file__)
    for name in ['release-install-17', 'release-verify-17']:
        file = build / name / 'run.json'
        bind(file)
        r = json.loads(file.read_text())
        assert r['complete'] and r['returncode'] == 0 and r['changedInputs'] == []
        assert not r.get('timeout') and not r.get('error')
        for x in r['inputs'] + [r['stdout'], r['stderr']]:
            bind(x['file'], x['sha256'])
        assert r['stderr']['bytes'] == 0
    manifest_file = project / 'dist/release.json'
    report['manifest'] = bind(manifest_file)
    m = json.loads(manifest_file.read_text())
    assert m['kind'] == 'bend-default-equality-release' and m['artifact'] == 'equality-derived-b1'
    assert m['version'] == 1 and m['newBootstrap'] is False
    assert m['sourceSha256'] == SOURCE and m['runtimeSha256'] == RUNTIME
    files = {x['path']: x for x in m['files']}
    for path, expected in [('dist/typed-api.mjs', API), ('dist/base.bend', BASE), ('dist/release-lineage/checked-api.mjs', PARENT)]:
        assert files[path]['sha256'] == expected
    for group in [m['files'], m['checkout']]:
        assert len(group) == len({x['path'] for x in group})
        for x in group:
            p = Path(x['path'])
            assert not p.is_absolute() and '..' not in p.parts
            assert bind(project / p, x['sha256'])['bytes'] == x['bytes']
    checkout = {x['path']: x for x in m['checkout']}
    assert checkout['src/runtime.mjs']['sha256'] == RUNTIME
    bfile = project / 'dist/release-lineage/checked-bootstrap.json'
    b = json.loads(bfile.read_text())
    assert b['apiSha256'] == PARENT and b['sourceSha256'] == SOURCE and b['baseSha256'] == BASE
    assert b['provenance']['verifiedAfterBuild'] is True
    d = json.loads((project / 'dist/release-lineage/derivation.json').read_text())
    assert d['complete'] and d['newBootstrap'] is False
    assert d['original']['api']['sha256'] == PARENT and d['output']['sha256'] == API
    assert d['original']['bootstrapReport']['sha256'] == ident(bfile)['sha256']
    assert d['toolSnapshot']['sha256'] == files['dist/release-lineage/equality.mjs']['sha256']
    assert d['transform']['version'] == 6
    history = project / 'dist/release-history' / PRIOR
    previous_file = history / 'release.json'
    report['previousManifest'] = bind(previous_file)
    previous = json.loads(previous_file.read_text())
    assert next(x for x in previous['files'] if x['path'] == 'dist/typed-api.mjs')['sha256'] == PRIOR
    for x in previous['files']:
        p = Path(x['path'])
        assert p.parts[0] == 'dist'
        bind(history.joinpath(*p.parts[1:]), x['sha256'])
    start = root / 'implementation/phase30/start-state.json'
    bind(start)
    protected = json.loads(start.read_text())['protectedPreexisting']
    assert len(protected) == 103
    histories = set()
    for x in protected:
        bind(root / x['path'], x['sha256'])
        marker = 'selfhost/dist/release-history/'
        if x['path'].startswith(marker):
            histories.add(x['path'][len(marker):].split('/')[0])
    assert len(histories) == 4 and PRIOR not in histories
    report['protectedFilesUnchanged'] = 103
    report['protectedHistoryDirectories'] = sorted(histories)
    launcher_file = build / 'release-smoke-17/launcher.json'
    report['smokeLauncher'] = bind(launcher_file)
    launcher = json.loads(launcher_file.read_text())
    assert launcher['complete'] and launcher['pass'] and launcher['steps'] == 42
    assert launcher['expectedApi'] == API and launcher['cpu'] == 1 and not launcher.get('error')
    for x in launcher['inputs'] + [launcher['checks']]:
        bind(x['file'], x['sha256'])
    checkfile = Path(launcher['checks']['file'])
    checks = json.loads(checkfile.read_text())
    assert checks['pass'] and checks['apiSha256'] == API and checks['actualCpu'] == '1'
    assert checks['changedOrdinaryInputs'] == checks['changedRelocatedInputs'] == checks['changedFixtures'] == []
    assert len(checks['steps']) == len({x['name'] for x in checks['steps']}) == 42
    for x in checks['steps']:
        assert x['pass'] and x['assertion'] and x['exitCode'] == 0
        assert not any(x.get(key) for key in ['error', 'signal', 'timedOut', 'overflow'])
        bind(checkfile.parent / x['stdout'], x['outputSha256'])
        bind(checkfile.parent / x['stderr'])
    assert checks['release']['sha256'] == report['manifest']['sha256']
    assert checks['relocation']['noUpstreamCheckout'] is True
    assert checks['relocation']['createdUpstreamCheckout'] is False
    relocated = Path(checks['relocation']['root'])
    assert bind(relocated / 'dist/release.json')['sha256'] == report['manifest']['sha256']
    assert bind(relocated / 'dist/typed-api.mjs')['sha256'] == API
    assert bind(relocated / 'src/runtime.mjs')['sha256'] == RUNTIME
    bind(checks['toolchain']['file'], checks['toolchain']['sha256'])
    assert checks['toolchain']['sha256'] == '8a3f27cb0d8904a46986cbcc6437c2049939204d1c9f7caa3898c36ba067c0e2'
    assert checks['environment']['remainingBendKeys'] == []
    report['smokeSteps'] = 42
    report['ordinaryAndRelocatedRuntime'] = RUNTIME
    report['approvedEnvironmentBoundary'] = 'Outer parent tool invocation; receipt environment labels do not self-certify approval. Relocation keeps the external pinned Clang toolchain.'
    for x in report['inputs']:
        assert ident(x['file']) == x
    report['complete'] = report['pass'] = True
except BaseException as error:
    report['error'] = repr(error)
finally:
    save()
print(json.dumps({k: report.get(k) for k in ['complete', 'pass', 'smokeSteps', 'protectedFilesUnchanged', 'error']}))
raise SystemExit(0 if report['pass'] else 1)
