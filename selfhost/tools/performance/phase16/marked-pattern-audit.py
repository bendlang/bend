#!/usr/bin/env python3
from pathlib import Path
import json,hashlib
root=Path(__file__).resolve().parents[4];build=root/'selfhost/build/phase16';j=lambda p:json.loads(p.read_text());ident=lambda p:{'file':str(p),'sha256':hashlib.sha256(p.read_bytes()).hexdigest()}
bp=build/'marked-pattern-baseline-02/selected/paired.json';cp=build/'marked-pattern-validation-01/selected/paired.json';b=j(bp);c=j(cp);before={(r['id'],r['lane']):r for r in b['rows']};after={(r['id'],r['lane']):r for r in c['rows']};assert before.keys()==after.keys();new=[];lost=[];remaining=[];primitive=[]
for key,r in after.items():
 old=before[key]
 if r['exactAgreement'] and not old['exactAgreement']:new.append({'id':key[0],'lane':key[1]})
 if not r['exactAgreement'] and old['exactAgreement']:lost.append({'id':key[0],'lane':key[1]})
 if not r['exactAgreement']:remaining.append({'id':key[0],'lane':key[1]})
 for axis in ['status','phase','checked','exitCode']:
  if old['candidate'].get(axis)!=r['candidate'].get(axis):primitive.append({'id':key[0],'lane':key[1],'axis':axis,'before':old['candidate'].get(axis),'after':r['candidate'].get(axis),'reference':r['reference'].get(axis)})
health=[]
for run in ['marked-pattern-baseline-02','marked-pattern-validation-01']:
 report=j(build/run/'report.json');assert report['complete'];
 for p in report['phases']:
  e=p['execution'];assert e['error'] is None and not e['timedOut'] and not e['overflow'] and e['signal'] is None and e['exitCode'] in [0,1]
 for side in ['reference','candidate']:
  p=build/run/'selected'/f'{side}.json';d=j(p);assert len(d['results'])==114;assert all(not w['errors'] and w['stats']['timeouts']==0 and w['stats']['failures']==0 for w in d['workers']);health.append({'run':run,'side':side,'identity':ident(p),'selectedComplete':d['selectedComplete'],'workers':d['workers']})
assert not lost;assert all(r['after']==r['reference'] for r in primitive)
focus=j(build/'marked-pattern-checked-01/validation-001/report.json');demand=j(build/'marked-pattern-demand-01/report.json');assert focus['pass'] and demand['pass'];m=j(build/'marked-pattern-source-01/manifest.json')
files=[Path(__file__),root/'design/phase16/marked_pattern_quantity.md',root/'experiments/phase16/P16-marked-pattern-quantity.md',build/'marked-pattern-source-01/manifest.json',build/'marked-pattern-source-01/src_front_elaborate.bend.patch',build/'marked-pattern-controls-02/manifest.json',build/'marked-pattern-controls-02/selection.json',build/'marked-pattern-checked-01/attempt.json',build/'marked-pattern-checked-01/validation-001/report.json',build/'marked-pattern-demand-01/report.json',bp,cp]
report={'complete':True,'scopedPass':True,'observations':114,'baselineExact':sum(r['exactAgreement']for r in b['rows']),'candidateExact':sum(r['exactAgreement']for r in c['rows']),'newExact':new,'lostExact':lost,'remaining':remaining,'primitiveChangesTowardReference':primitive,'health':health,'sourceChanges':m['changes'],'identities':[ident(p)for p in files],'limits':'All82 prior observations remain selected.43differences remain:30chronology,2offload,10marked formatting,1unchanged term width. No full-corpus or timing claim.'};out=build/'marked-pattern-audit-01.json';assert not out.exists();out.write_text(json.dumps(report,indent=2)+'\n');print(json.dumps({k:report[k]for k in ['complete','scopedPass','observations','baselineExact','candidateExact','sourceChanges']}))
