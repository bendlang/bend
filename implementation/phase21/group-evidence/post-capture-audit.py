"""Check protected files, frozen identities and historical prerequisites after recovery."""
from pathlib import Path
import hashlib, json, subprocess, traceback

R = Path(__file__).resolve().parents[3]
E = Path(__file__).resolve().parent

def sha(p):
    h = hashlib.sha256()
    with p.open('rb') as f:
        for block in iter(lambda: f.read(1024 * 1024), b''): h.update(block)
    return h.hexdigest()

def read(p): return json.loads(p.read_text())
def ident(p): return {'path': p.relative_to(R).as_posix(), 'sha256': sha(p), 'bytes': p.stat().st_size}

out = E / 'post-capture-audit.json'
assert not out.exists()
report = {'kind': 'phase21-post-capture-identity-audit', 'complete': False, 'pass': False}
try:
    inv = read(E / 'capsule-01/inventory.json'); idx = {x['path']: x for x in inv['members']}
    recovery = read(E / 'recovery-01.json')
    assert recovery['complete'] and recovery['pass']
    assert recovery['manifestSha256'] == sha(E / 'capsule-01/manifest.json')
    assert recovery['inventorySha256'] == sha(E / 'capsule-01/inventory.json')
    protected = read(E / 'phase6-start-state.json')['rows']; assert len(protected) == 75
    status = {x[3:]: x[:2] for x in subprocess.check_output(
        ['git', 'status', '--porcelain=v1', '--untracked-files=all'], cwd=R, text=True).splitlines()}
    for x in protected:
        assert sha(R / x['path']) == x['sha256'] and status.get(x['path']) == x['status'], x['path']
        assert x['path'] not in idx
    assert not any('/phase6/' in n for n in idx)
    assert not any(n.startswith('selfhost/build/phase19/context-') for n in idx)
    assert not any(set(Path(n).parts) & {'.git', '.ssh', '.aws', '.kube'} for n in idx)
    for row in inv['members']:
        assert row['type'] == 'file'
        p = R / row['path']
        assert p.stat().st_size == row['bytes'] and sha(p) == row['sha256']
        assert p.stat().st_mode & 0o7777 == row['mode']
    root = read(E / 'root-release-freeze.json'); frozen = {}
    for x in root['files'] + root['inputs']:
        p = Path(x.get('file', x.get('path')))
        if not p.is_absolute(): p = R / p
        n = p.relative_to(R).as_posix()
        assert sha(p) == x['sha256'] and idx[n]['sha256'] == x['sha256'], n
        frozen[n] = x['sha256']
    for x in read(E / 'root-freeze.json')['inputs']:
        assert sha(R / x['path']) == x['sha256'], x['path']
    prior_file = R / 'implementation/phase20/declaration-evidence/capsule-01/inventory.json'
    prior = {x['path']: x for x in read(prior_file)['members']}
    integration = read(R / 'selfhost/build/phase21/group-range-integration-audit-01/report.json')
    historical_names = [Path(x['file']).relative_to(R).as_posix() for x in integration['inputs'] if '/build/phase20/' in x['file']]
    historical_names += ['selfhost/build/phase20/import-diagnostic-build-04/equality/api.mjs',
                         'selfhost/build/phase20/import-diagnostic-build-04/attempt.json']
    historical = []
    for n in sorted(set(historical_names)):
        assert n in prior and sha(R / n) == prior[n]['sha256'], n
        historical.append({'path': n, 'sha256': prior[n]['sha256'], 'externalPriorCapsuleMatch': True})
    expected = read(E / 'source-delta.json')
    assert recovery['sourceReconstruction']['files'] == expected['count'] == 214
    assert recovery['sourceReconstruction']['baselineCommit'] == expected['baselineCommit'] == 'c385d3913e9f10c6c4d9c5cfef3f34bc0682d351'
    assert sha(R / 'selfhost/dist/typed-api.mjs') == inv['finalApiSha256'] == '44094e58cb0ef033e2c08c2827565e859c3594b3136868d4f821262145aea7f0'
    for n in expected['changedFiles']:
        assert sha(R / 'selfhost' / n) == idx[inv['finalSource'] + '/' + n]['sha256']
    report.update({'complete': True, 'pass': True,
        'protectedPhase6': {'count': 75, 'hashesAndStatusesUnchanged': True, 'payloadExcluded': True},
        'allCapturedInputsStillIdentical': len(idx), 'rootFrozenInputs': len(frozen),
        'allRootFrozenInputsCapturedUnchanged': True, 'historicalComparisonIdentities': historical,
        'privateContextualPayloadExcluded': True, 'sourceReconstructed': 214,
        'changedFiles': expected['changedFiles'], 'manifestSha256': recovery['manifestSha256'],
        'inventorySha256': recovery['inventorySha256'],
        'limitations': 'Identity/path/recovery audit, not a comprehensive secret scanner or compiler conformance rerun.',
        'inputs': [ident(Path(__file__)), ident(E / 'phase6-start-state.json'),
                   ident(E / 'root-release-freeze.json'), ident(E / 'recovery-01.json'), ident(prior_file)]})
except Exception:
    report['error'] = traceback.format_exc()
with out.open('x') as f: json.dump(report, f, indent=2); f.write('\n')
print(json.dumps({'pass': report['pass'], 'report': str(out), 'error': report.get('error')}))
if not report['pass']: raise SystemExit(1)
