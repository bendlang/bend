#!/usr/bin/env python3
"""Audit exact parser-family outcomes without relaxing the original oracle."""
import pathlib,json,hashlib,re,sys,shutil
ROOT=pathlib.Path(__file__).resolve().parents[4]
ATTEMPT, FAMILY, CONTROLS, RENDERER, OUT=map(pathlib.Path,sys.argv[1:])
OUT.mkdir();shutil.copy2(__file__,OUT/pathlib.Path(__file__).name)
read=lambda p:json.loads(p.read_text())
ident=lambda p:{'file':str(p.resolve()),'sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'bytes':p.stat().st_size}
basefile=ROOT/'selfhost/build/phase14/frontend-audit-02/candidate.json';base=read(basefile)
attempt=read(ATTEMPT/'attempt.json');focused=read(ATTEMPT/'validation-001/report.json');family=read(FAMILY/'report.json');paired=read(FAMILY/'selected/paired.json');controls=read(CONTROLS/'report.json');renderer=read(RENDERER/'report.json')
old={(r['id'],r['lane']):r for r in base['results']}
keys=['status','phase','checked','typeAccepted','proofTrust','kernelChecked','unsafeDefinitions','exitCode','output']
obs=lambda r:{k:r.get(k) for k in keys}
strip=lambda s:re.sub(r'\n[ \t]*\|[ \t]*\^+[ \t]*(?=\n|$)','',s or '')
rows=[]
for r in paired['rows']:
 b=old[r['id'],r['lane']]['result'];a=r['candidate']
 rows.append({'id':r['id'],'lane':r['lane'],'exactReference':r['exactAgreement'],'semanticAxesUnchanged':obs(a)==obs(b),'onlyCaretAdded':a.get('diagnostic')!=b.get('diagnostic') and strip(a.get('diagnostic'))==b.get('diagnostic'),'reference':r['reference'],'candidate':a,'baseline':b})
source=pathlib.Path(attempt['snapshot']['root'])/'src';before=ROOT/'selfhost/build/phase14/combined-01/snapshot/src';changed=[]
for p in sorted(source.rglob('*')):
 if p.is_file() and (not (before/p.relative_to(source)).is_file() or p.read_bytes()!=(before/p.relative_to(source)).read_bytes()): changed.append(str(p.relative_to(source)))
p=source/'front/parser.bend';q=before/'front/parser.bend'
healthy=lambda doc:doc['complete'] and all(not any(p['execution'].get(k) for k in ['signal','error','timedOut','overflow']) and p['execution']['exitCode'] in [0,1] for p in doc['phases'])
files=[basefile,ATTEMPT/'attempt.json',ATTEMPT/'validation-001/report.json',FAMILY/'report.json',FAMILY/'selected/paired.json',CONTROLS/'report.json',RENDERER/'report.json',pathlib.Path(__file__)]
report={'kind':'phase15-parser-caret-final-gates','complete':True,'inputs':[ident(p) for p in files],'attemptApi':attempt['api'],'checkedApi':attempt['checkedApi'],'sourceChanges':changed,'sourceCost':{'physicalLines':len(p.read_text().splitlines())-len(q.read_text().splitlines()),'bytes':p.stat().st_size-q.stat().st_size},'focused':{'complete':focused['complete'],'pass':focused['pass'],'observations':focused['selected']['candidate']['probes'],'exactDifferences':focused['selected']['exactDifferences']},'family':{'complete':family['complete'],'strictPass':family['pass'],'observations':len(rows),'exactReference':sum(r['exactReference'] for r in rows),'remainingDifferences':[{'id':r['id'],'lane':r['lane']} for r in rows if not r['exactReference']],'rows':rows},'parserControls':{'complete':controls['complete'],'pass':controls['pass'],'cases':len(controls['rows']),'exactReference':controls['exactReferenceCount'],'remainingDifferences':[r['label'] for r in controls['rows'] if not r['exactReference']]},'sharedRenderer':{'complete':renderer['complete'],'pass':renderer['pass'],'cases':len(renderer['rows'])},'executionHealth':{'focused':healthy(focused),'family':healthy(family)},'scope':'Parser rendering only; no performance or full-conformance claim; direct control exact gaps remain visible.'}
report['scopedInvariantsPass']=healthy(focused) and healthy(family) and focused['pass'] and controls['pass'] and renderer['pass'] and len(rows)==132 and all(r['semanticAxesUnchanged'] and r['onlyCaretAdded'] for r in rows) and changed==['front/parser.bend']
(OUT/'report.json').write_text(json.dumps(report,indent=2)+'\n')
print(json.dumps({k:v for k,v in report.items() if k not in ['inputs','family']},indent=2));print('Family:',len(rows),'observations,',sum(r['exactReference'] for r in rows),'exact')
if not report['scopedInvariantsPass']:sys.exit(1)
