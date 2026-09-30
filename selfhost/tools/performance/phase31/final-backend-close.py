#!/usr/bin/env python3
"""Audit60 retained pilot rows plus21 authorized native retry rows; no tests."""
from pathlib import Path
import hashlib,json,shutil,sys

original_file,retry_plan_file,retry_dir,outer_dir,out=(Path(x).resolve() for x in sys.argv[1:])
out.mkdir(parents=True,exist_ok=False)
def ident(p):
 p=Path(p).resolve();raw=p.read_bytes()
 return dict(file=str(p),sha256=hashlib.sha256(raw).hexdigest(),bytes=len(raw))
inputs={}
def keep(p,digest=None):
 row=ident(p)
 if digest:assert row['sha256']==digest,str(p)
 inputs[row['file']]=row;return row
def read(p):keep(p);return json.loads(p.read_text())
original=read(original_file);retry_plan=read(retry_plan_file)
retry=read(retry_dir/'report.json');outer=read(outer_dir/'run.json')
assert original['complete'] and not original['agreementComplete'] and len(original['rows'])==81
assert retry_plan['complete'] and not retry_plan['executed']
assert outer['complete'] and outer['returncode']==0 and outer['changedInputs']==[] and not outer.get('timeout')
assert retry['complete'] and not retry.get('error') and retry['changedInputs']==[]
assert len(retry['rows'])==21
fields=['referenceVerdict','candidateVerdict','reference','candidate','exactAgreement','semanticAgreement']
canonical=lambda r:json.dumps({k:r[k] for k in fields},sort_keys=True,separators=(',',':'))
expected={(r['id'],r['lane']):r for r in retry_plan['expectedRows']}
assert len(expected)==21
for r in retry['rows']:
 assert r['exactAgreement'] and r['semanticAgreement']
 assert canonical(r)==canonical(expected.pop((r['id'],r['lane'])))
assert not expected
retained=[r for r in original['rows'] if r['batch']!='pilot-native']
excluded=[r for r in original['rows'] if r['batch']=='pilot-native']
assert len(retained)==60 and len(excluded)==21 and all(r['acceptedCampaignObservation'] for r in retained)
assert sum(not r['acceptedCampaignObservation'] for r in excluded)==17
for directory in [*[Path(s['receipt']['file']).parent for s in original['steps']],retry_dir]:
 archive_file=directory/'archive.json';archive=read(archive_file)
 assert archive['verifiedFiles']>0 and archive['verifiedFiles']==len(archive['files'])
 keep(archive['archive']['file'],archive['archive']['sha256'])
for source in [outer,retry,original]:
 for i in source.get('inputs',[]):keep(i['file'],i['sha256'])
for i in retry_plan['inputs']:keep(i['file'],i['sha256'])
rows=[{**r,'acquisitionGroup':'original-first-six-batches'} for r in retained]
rows += [{**r,'batch':'pilot-native','acquisitionGroup':'approved-context-native21-retry','acceptedCampaignObservation':True} for r in retry['rows']]
assert len(rows)==len({(r['id'],r['lane']) for r in rows})==81
counts={v:sum(r['candidateVerdict']==v for r in rows) for v in ['pass','not-applicable','fail']}
assert counts=={'pass':69,'not-applicable':8,'fail':4}
keep(Path(__file__))
for i in inputs.values():assert ident(i['file'])==i
report=dict(kind='phase31-final07-backend-pilot-consolidation',complete=True,agreementComplete=True,
 inputs=list(inputs.values()),rows=rows,exactRows=81,counts=counts,
 retainedRows=60,retriedRows=21,failedDefaultCampaign=ident(original_file),retry=ident(retry_dir/'report.json'),
 retryOuter=ident(outer_dir/'run.json'),failedDefaultRows=excluded,
 scope='60 accepted rows from first six default-context batches plus21 native rows from root-approved retry. Raw default campaign remains failed; not one successful81-row execution or broad native conformance.')
(out/'report.json').write_text(json.dumps(report,indent=2)+'\n')
shutil.copyfile(Path(__file__),out/'consumed-close.py')
print(json.dumps(dict(complete=True,agreementComplete=True,exactRows=81,counts=counts)))
