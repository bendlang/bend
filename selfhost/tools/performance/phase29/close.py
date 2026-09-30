#!/usr/bin/env python3
"""Close validated Phase29 evidence without changing any earlier attempt."""
from pathlib import Path
import hashlib,json,shutil,subprocess
ROOT=Path(__file__).resolve().parents[4];RAW=ROOT/'selfhost/build/phase29';OUT=ROOT/'implementation/phase29'
def digest(p):return hashlib.sha256(p.read_bytes()).hexdigest()
start=json.loads((OUT/'start-state.json').read_text())
for entry in start['protectedPreexisting']:
 p=ROOT/entry['path'];assert p.stat().st_size==entry['bytes'] and digest(p)==entry['sha256'],entry['path']
assert not subprocess.check_output(['git','diff',start['head'],'--name-only','--','bend2'],cwd=ROOT,text=True).strip()
result=json.loads((OUT/'results.json').read_text());assert result['complete']
audit=json.loads((OUT/'measurement-audit.json').read_text());assert audit.get('complete') is True or audit.get('pass') is True,audit.keys()
for name in ['fixture-screen-04','fixture-confirm-04','transfer-timing-04','transfer-confirm-04','components-confirm-04','evening-confirm-04']:
 r=json.loads((RAW/name/'report.json').read_text());assert r['complete'] and r['allCasesMeasured'],name
r=json.loads((RAW/'application-timing-04/report.json').read_text());assert r['complete'] and r['allSamplesValid']
attempt=json.loads((RAW/'attempt-04/attempt.json').read_text());release=json.loads((ROOT/'selfhost/dist/release.json').read_text())
assert next(x for x in release['files'] if x['path']=='dist/typed-api.mjs')['sha256']==attempt['api']['sha256']
assert release['runtimeSha256']==attempt['runtime']['sha256']
for name in ['attempt-04/validation-001/report.json','upstream-js-04/report.json','controls-final-04/report.json']:
 r=json.loads((RAW/name).read_text());assert r['complete'] and r['pass']
for name in ['corpus-04/report.json','transfer-04/report.json','component-candidate-04/report.json','application-candidate-04/report.json']:
 assert json.loads((RAW/name).read_text())['complete'],name
assert json.loads((RAW/'release-verify.stdout').read_text())['complete']
assert json.loads((RAW/'installed-cli-02.json').read_text())['complete']
snap=RAW/'consumed-tools';assert not snap.exists(),'Close once; never overwrite a consumed snapshot'
shutil.copytree(ROOT/'selfhost/tools/performance/phase29',snap/'selfhost/tools/performance/phase29',ignore=shutil.ignore_patterns('__pycache__'))
for name in ['phase25/campaign.py','phase25/emit.mjs','phase25/check.mjs',
 'phase26/emit.mjs','phase26/corpus.py','phase27/component-membership.bend',
 'phase27/component-membership-oracle.mjs','phase28/emit-program.mjs','phase28/measure-application.py']:
 source=ROOT/'selfhost/tools/performance'/name
 if source.exists():
  dest=snap/'selfhost/tools/performance'/name;dest.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(source,dest)
shutil.copy2(ROOT/'selfhost/dist/release.json',RAW/'installed-release.json')
receipt={'complete':True,'baselineCommit':start['head'],'protectedFilesVerified':len(start['protectedPreexisting']),
 'pinnedUpstreamUnchanged':True,'attemptApiSha256':attempt['api']['sha256'],'runtimeSha256':attempt['runtime']['sha256'],
 'releaseManifestSha256':digest(RAW/'installed-release.json'),'resultsSha256':digest(OUT/'results.json'),
 'measurementAuditSha256':digest(OUT/'measurement-audit.json'),
 'scope':'Protected bytes, closed successful reports, release identity and consumed-tool capture. Semantic and measurement scopes remain in their independent reports.'}
for p in [RAW/'closure.json',OUT/'closure.json']:p.write_text(json.dumps(receipt,indent=2)+'\n')
print(json.dumps(receipt,indent=2))
