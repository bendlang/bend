#!/usr/bin/env python3
"""Audit protected files, canonical checked source and installed smoke results."""
from pathlib import Path
import hashlib,json,sys
ROOT=Path(__file__).resolve().parents[2]
phase=ROOT/'selfhost/build/phase27';out=Path(sys.argv[1]);assert not out.exists()
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
start=json.loads((ROOT/'implementation/phase27/start-state.json').read_text())
protected=start['protectedPreexisting'];assert len(protected)==103
changed=[r['path'] for r in protected if not (ROOT/r['path']).is_file() or sha(ROOT/r['path'])!=r['sha256']]
assert not changed,changed
project=ROOT/'selfhost';attempt=json.loads((phase/'attempt-02/attempt.json').read_text())
snapshot=Path(attempt['snapshot']['root'])
manifest=json.loads((project/'src/compiler.json').read_text())
files=manifest['modules']+['src/compiler.json','src/runtime.mjs','src/runtime/js/core.mjs']
for f in files:assert (project/f).read_bytes()==(snapshot/f).read_bytes(),f
release=json.loads((project/'dist/release.json').read_text())
assert sha(project/'dist/typed-api.mjs')==attempt['api']['sha256']
assert release['runtimeSha256']==sha(project/'src/runtime.mjs')
verification=json.loads((phase/'release-verify.log').read_text());assert verification['complete']
smokes={'closure':'103\n','u32':'2496 2397\n'}
for name,expected in smokes.items():
    assert (phase/f'cli-{name}.stdout').read_text()==expected
    assert (phase/f'cli-{name}.stderr').read_bytes()==b''
report={'complete':True,'protectedPreexistingCount':len(protected),'changedProtected':changed,
        'canonicalSourceMatchesCheckedSnapshot':True,'canonicalFiles':len(files),
        'installedApiSha256':attempt['api']['sha256'],'checkedParentSha256':attempt['checkedApi']['sha256'],
        'sourceSha256':release['sourceSha256'],'runtimeSha256':release['runtimeSha256'],
        'releaseManifestSha256':sha(project/'dist/release.json'),'releaseVerification':verification,
        'smokeOutput':smokes,'scope':'Canonical compiler modules/manifest/runtime match immutable checked attempt; documentation and standalone diagnostic tools are not compiler inputs.'}
out.write_text(json.dumps(report,indent=2)+'\n')
