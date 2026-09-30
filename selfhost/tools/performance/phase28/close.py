#!/usr/bin/env python3
"""Verify this measurement phase changed no compiler or protected starting file."""
from pathlib import Path
import hashlib,json,shutil,subprocess

ROOT=Path(__file__).resolve().parents[4]
RAW=ROOT/'selfhost/build/phase28'
OUT=ROOT/'implementation/phase28'
start=json.loads((OUT/'start-state.json').read_text())
digest=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
protected=start['protectedPreexisting']
for entry in protected:
    p=ROOT/entry['path']
    assert p.stat().st_size==entry['bytes'] and digest(p)==entry['sha256'],entry['path']
changed=subprocess.check_output(['git','diff',start['head'],'--name-only','--',
    'selfhost/src','selfhost/dist','bend2'],cwd=ROOT,text=True).splitlines()
assert not changed,changed
assert not subprocess.check_output(['git','diff','--cached','--name-only'],cwd=ROOT,text=True).strip()
verify=json.loads((RAW/'release-verification.json').read_text())
assert verify.get('ok') is True or verify.get('complete') is True,verify
snap=RAW/'consumed-tools'
assert not snap.exists(),'Close once; preserve historical captures'
paths=[ROOT/'selfhost/tools/performance'/phase for phase in ['phase28']]
for p in paths:
    shutil.copytree(p,snap/p.relative_to(ROOT),ignore=shutil.ignore_patterns('__pycache__'))
for name in ['selfhost/tools/performance/phase25/campaign.py',
             'selfhost/tools/performance/phase25/emit.mjs',
             'selfhost/tools/performance/phase26/emit.mjs']:
    dest=snap/name;dest.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(ROOT/name,dest)
receipt={'complete':True,'baselineCommit':start['head'],
    'compilerPathsUnchanged':['selfhost/src','selfhost/dist','bend2'],
    'protectedFilesVerified':len(protected),'releaseVerificationSha256':digest(RAW/'release-verification.json'),
    'scope':'Byte preservation and installed release identity only; no new broad conformance or performance gate.'}
for p in [RAW/'closure.json',OUT/'closure.json']:
    p.write_text(json.dumps(receipt,indent=2)+'\n')
print(json.dumps(receipt,indent=2))
