#!/usr/bin/env python3
from pathlib import Path
import json,hashlib
root=Path(__file__).resolve().parents[4];build=root/'selfhost/build/phase16';j=lambda p:json.loads(p.read_text());ident=lambda p:{'file':str(p),'sha256':hashlib.sha256(p.read_bytes()).hexdigest()}
bp=build/'empty-call-pattern-baseline-02/selected/paired.json';cp=build/'empty-call-pattern-validation-01/selected/paired.json';b=j(bp);c=j(cp);before={(r['id'],r['lane']):r for r in b['rows']};after={(r['id'],r['lane']):r for r in c['rows']};assert before.keys()==after.keys();new=[];lost=[];remaining=[];primitive=[]
for key,r in after.items():
 old=before[key]
 if r['exactAgreement'] and not old['exactAgreement']:new.append({'id':key[0],'lane':key[1]})
 if not r['exactAgreement'] and old['exactAgreement']:lost.append({'id':key[0],'lane':key[1]})
 if not r['exactAgreement']:remaining.append({'id':key[0],'lane':key[1]})
 for axis in ['status','phase','checked','exitCode']:
  if old['candidate'].get(axis)!=r['candidate'].get(axis):primitive.append({'id':key[0],'lane':key[1],'axis':axis,'before':old['candidate'].get(axis),'after':r['candidate'].get(axis),'reference':r['reference'].get(axis)})
health=[]
for run in ['empty-call-pattern-baseline-02','empty-call-pattern-validation-01']:
 report=j(build/run/'report.json');assert report['complete'];
 for p in report['phases']:
  e=p['execution'];assert e['error'] is None and not e['timedOut'] and not e['overflow'] and e['signal'] is None and e['exitCode'] in [0,1]
 for side in ['reference','candidate']:
  p=build/run/'selected'/f'{side}.json';d=j(p);assert len(d['results'])==82;assert all(not w['errors'] and w['stats']['timeouts']==0 and w['stats']['failures']==0 for w in d['workers']);health.append({'run':run,'side':side,'identity':ident(p),'selectedComplete':d['selectedComplete'],'workers':d['workers']})
assert not lost;assert all(r['after']==r['reference'] for r in primitive)
focus=j(build/'empty-call-pattern-checked-01/validation-001/report.json');demand=j(build/'empty-call-pattern-demand-01/report.json');assert focus['pass'] and demand['pass'];m=j(build/'empty-call-pattern-source-01/manifest.json')
files=[Path(__file__),root/'design/phase16/empty_call_patterns.md',root/'experiments/phase16/P16-empty-call-patterns.md',build/'empty-call-pattern-source-01/manifest.json',build/'empty-call-pattern-source-01/elaborate.patch',build/'empty-call-pattern-controls-02/manifest.json',build/'empty-call-pattern-controls-02/selection.json',build/'empty-call-pattern-checked-01/attempt.json',build/'empty-call-pattern-checked-01/validation-001/report.json',build/'empty-call-pattern-demand-01/report.json',bp,cp]
report={'complete':True,'scopedPass':True,'observations':82,'baselineExact':sum(r['exactAgreement']for r in b['rows']),'candidateExact':sum(r['exactAgreement']for r in c['rows']),'newExact':new,'lostExact':lost,'remaining':remaining,'primitiveChangesTowardReference':primitive,'health':health,'sourceChanges':m['changes'],'identities':[ident(p)for p in files],'limits':'All50 prior chronology observations remain selected.30chronology +2marked-bound +2offload differences remain. No full-corpus or timing claim.'};out=build/'empty-call-pattern-audit-01.json';assert not out.exists();out.write_text(json.dumps(report,indent=2)+'\n');print(json.dumps({k:report[k]for k in ['complete','scopedPass','observations','baselineExact','candidateExact','sourceChanges']}))
