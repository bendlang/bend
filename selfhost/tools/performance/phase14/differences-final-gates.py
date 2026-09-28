#!/usr/bin/env python3
"""Record exact family results and non-diagnostic invariants; never relabel failure."""
import pathlib,json,hashlib,re,sys
ROOT=pathlib.Path(__file__).resolve().parents[4]
OUT=ROOT/'selfhost/build/phase14/differences-final-gates-01';OUT.mkdir()
identity=lambda f:{'file':str(f),'sha256':hashlib.sha256(f.read_bytes()).hexdigest()}
paths=['selfhost/build/phase12/frontend-03/candidate.json','selfhost/build/phase14/differences-build-02/attempt.json','selfhost/build/phase14/differences-build-02/validation-001/report.json','selfhost/build/phase14/differences-render-controls-02/report.json','selfhost/build/phase14/differences-family-02/report.json','selfhost/build/phase14/differences-family-02/selected/paired.json','selfhost/build/phase14/differences-boundary-baseline-01/report.json','selfhost/build/phase14/differences-boundary-candidate-01/report.json']
read=lambda p:json.loads((ROOT/p).read_text())
base=read(paths[0]);attempt=read(paths[1]);focused=read(paths[2]);renderer=read(paths[3]);family=read(paths[4]);paired=read(paths[5]);old={(r['id'],r['lane']):r for r in base['results']}
keys=['status','phase','checked','typeAccepted','proofTrust','kernelChecked','unsafeDefinitions','exitCode','output']
obs=lambda r:{k:r.get(k) for k in keys}
strip=lambda s:re.sub(r'\n *\|[ \t]*\^+','',s or '')
familyrows=[]
for r in paired['rows']:
 b=old[(r['id'],r['lane'])]['result'];a=r['candidate']
 familyrows.append({'id':r['id'],'exactReference':r['exactAgreement'],'semanticAxesUnchanged':obs(a)==obs(b),'onlyCaretAdded':a.get('diagnostic')!=b.get('diagnostic') and strip(a.get('diagnostic'))==b.get('diagnostic'),'reference':r['reference'],'candidate':a,'baseline':b})
boundary=[]
for label in ['baseline','candidate']:
 p=f'selfhost/build/phase14/differences-boundary-{label}-01/selected/candidate.json';paths.append(p);boundary.append(read(p))
prior={(r['id'],r['lane']):r for r in boundary[0]['results']};boundrows=[]
for r in boundary[1]['results']:
 b=prior[(r['id'],r['lane'])]['result'];a=r['result'];boundrows.append({'id':r['id'],'semanticAxesUnchanged':obs(a)==obs(b),'diagnosticUnchangedExceptCaret':strip(a.get('diagnostic'))==b.get('diagnostic',''),'baseline':b,'candidate':a})
source=pathlib.Path(attempt['snapshot']['root'])/'src';oldsource=ROOT/'selfhost/build/phase12/integrated-03/snapshot/src';changed=[]
for p in sorted(source.rglob('*')):
 if p.is_file():
  q=oldsource/p.relative_to(source)
  if not q.is_file() or p.read_bytes()!=q.read_bytes():changed.append(str(p.relative_to(source)))
p=source/'diagnostic/render.bend';q=oldsource/'diagnostic/render.bend'
health=[]
for pth in [paths[2],paths[4],paths[6],paths[7]]:
 x=read(pth);health.append({'file':str(ROOT/pth),'complete':x['complete'],'pass':x['pass'],'processesHealthy':all(not any(p['execution'].get(k) for k in ['signal','error','timedOut','overflow']) and p['execution']['exitCode'] in [0,1] for p in x['phases'])})
report={'kind':'phase14-checker-caret-final-gates','complete':True,'inputs':[identity(ROOT/p) for p in paths]+[identity(pathlib.Path(__file__).resolve())],'attemptApi':attempt['api'],'checkedApi':attempt['checkedApi'],'sourceChanges':changed,'sourceCost':{'beforePhysicalLines':len(q.read_text().splitlines()),'afterPhysicalLines':len(p.read_text().splitlines()),'beforeBytes':q.stat().st_size,'afterBytes':p.stat().st_size,'newDefinitions':3},'focused':{'complete':focused['complete'],'pass':focused['pass'],'observations':focused['selected']['candidate']['probes'],'exactDifferences':focused['selected']['exactDifferences']},'renderer':{'complete':renderer['complete'],'pass':renderer['pass'],'cases':len(renderer['rows'])},'family':{'complete':family['complete'],'strictPass':family['pass'],'observations':len(familyrows),'exactReference':sum(r['exactReference'] for r in familyrows),'remainingDifferences':[r['id'] for r in familyrows if not r['exactReference']],'rows':familyrows},'boundary':{'observations':len(boundrows),'rows':boundrows},'executionHealth':health,'scope':'Renderer-only improvement; 71 exact family fixes, seven existing origin defects remain. No parser/span-production changes, no performance or full-conformance claim.'}
report['scopedInvariantsPass']=all(x['complete'] and x['processesHealthy'] for x in health) and focused['pass'] and renderer['pass'] and len(familyrows)==78 and sum(r['exactReference'] for r in familyrows)==71 and all(r['semanticAxesUnchanged'] and r['onlyCaretAdded'] for r in familyrows) and all(r['semanticAxesUnchanged'] and r['diagnosticUnchangedExceptCaret'] for r in boundrows) and changed==['diagnostic/render.bend']
(OUT/'report.json').write_text(json.dumps(report,indent=2)+'\n')
print(json.dumps({k:report[k] for k in ['complete','scopedInvariantsPass','sourceChanges','sourceCost','focused','renderer']},indent=2))
if not report['scopedInvariantsPass']:sys.exit(1)
