from pathlib import Path
import json,hashlib
root=Path.cwd();base=root/'selfhost/build/phase16';out=base/'checker-audit-01';out.mkdir()
def read(p):return json.loads(p.read_text())
def identity(p):return {'file':str(p.resolve()),'sha256':hashlib.sha256(p.read_bytes()).hexdigest()}
inputs=[]
def run(name,count):
 p=base/name;w=read(p/'report.json');assert w['complete'];x=read(p/'selected/paired.json');assert len(x['rows'])==count and not x['missing']
 for side in ['reference','candidate']:
  f=p/'selected'/f'{side}.json';r=read(f);inputs.append(identity(f));assert len(r['results'])==count and r['finished'] and not r['changedInputs'];assert not r['identity']['adapterChangedDuringRun'] and not r['identity']['changedArtifacts'];assert all(not v['errors'] and not v['stats']['timeouts'] and not v['stats']['failures'] for v in r['workers'])
 assert all(r['semanticAgreement'] for r in x['rows']);inputs.append(identity(p/'selected/paired.json'));return x['rows'],w
rows,w=run('checker-focused-02',55);assert sum(r['exactAgreement'] for r in rows)==13
bounds,bw=run('checker-boundaries-01',12);assert all(r['referenceVerdict']=='pass' and r['candidateVerdict']=='pass' for r in bounds);assert sum(r['exactAgreement'] for r in bounds)==6
plan=read(base/'checker-controls-01/plan.json')
for r in bounds:
 name=r['id'].split('/',1)[1]
 for side in ['candidate','reference']:
  diag=r[side].get('diagnostic') or ''
  if name in plan['noNoteExpected']:assert 'Note:' not in diag,(name,side)
  if name in plan['noteExpected']:assert diag.endswith('Note: +f can be used many times, so its type must be Data.'),(name,side)
  if name=='adt-first-field.bend':assert '- observed : Type' in diag and 'Missing' not in diag.split('Location:')[0]
  if name=='adt-second-field.bend':assert '- observed : Missing' in diag and '- first : Nat' in diag
  if name=='template-captured.bend':assert 'closed ~ arguments (x is a variable here' in diag
  if name=='template-free.bend':assert 'a defined name' in diag and 'closed ~ arguments' not in diag
source=read(base/'checker-source-02/manifest.json');report={'kind':'phase16-checker-wave1-scoped-audit','complete':True,'pass':True,'inputs':inputs+[identity(Path(__file__)),identity(base/'checker-source-02/manifest.json')],'selected':{'observations':55,'exact':13,'strictDifferences':42,'behaviorAgreement':55,'strictWorkflowPass':w['pass']},'boundaries':{'observations':12,'exact':6,'strictDifferences':6,'behaviorAgreement':12,'declaredOraclesPass':12,'noNoteControls':len(plan['noNoteExpected']),'noteControls':len(plan['noteExpected'])},'intendedDelta':'Diagnostics only. Content fixes preserve first original typed checker result, constructor owner/context, conditional caller-variable translation, upstream typeless observation and note. Full upstream exactness still requires source origins and other owned content corrections. No exact match is normalized.','sourceChanges':source['changes'],'scope':'Scoped assertions pass; 55-row strict comparison remains failed with42 known differences, custom12 remains6nonexact snippets. Full integration, source-span correction and performance not measured here.'};(out/'report.json').write_text(json.dumps(report,indent=2)+'\n');print(json.dumps({k:report[k] for k in ['complete','pass','selected','boundaries']}))
