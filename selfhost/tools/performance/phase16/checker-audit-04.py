from pathlib import Path
import json,hashlib
root=Path.cwd();base=root/'selfhost/build/phase16';out=base/'checker-audit-04';out.mkdir();inputs=[]
def ident(p):return {'file':str(p.resolve()),'sha256':hashlib.sha256(p.read_bytes()).hexdigest()}
def read(p):inputs.append(ident(p));return json.loads(p.read_text())
def rows(name,count):
 p=base/name;assert read(p/'report.json')['complete'];r=read(p/'selected/paired.json');assert len(r['rows'])==count and not r['missing'];assert all(x['semanticAgreement'] for x in r['rows'])
 for side in ['reference','candidate']:
  x=read(p/'selected'/f'{side}.json');assert x['finished'] and len(x['results'])==count and not x['changedInputs'] and not x['identity']['adapterChangedDuringRun'] and not x['identity']['changedArtifacts'];assert all(not y['errors'] and not y['stats']['timeouts'] and not y['stats']['failures'] for y in x['workers'])
 return {x['id']:x for x in r['rows']}
a=rows('checker-all-04',84);b=rows('checker-all-05',84)
assert {k for k in b if a[k]['candidate']!=b[k]['candidate']}=={'check/template_inst_cycle.bend'}
assert sum(x['exactAgreement'] for x in b.values())==25
u=rows('checker-name-baseline-01',12);v=rows('checker-name-candidate-01',12)
changed={'check/template_inst_cycle.bend','p16-checker-names/prior-other-template.bend','p16-checker-names/prior-repeated-instance.bend'}
assert {k for k in v if u[k]['candidate']!=v[k]['candidate']}==changed
assert 'Location: bounce~0' in b['check/template_inst_cycle.bend']['candidate']['diagnostic']
assert 'Location: bad~0' in v['p16-checker-names/prior-other-template.bend']['candidate']['diagnostic']
repeated=v['p16-checker-names/prior-repeated-instance.bend'];assert 'Location: bad~1' in repeated['reference']['diagnostic'] and 'Location: bad~2' in repeated['candidate']['diagnostic']
d=read(base/'checker-name-direct-03/report.json');assert d['complete'] and not d['pass'] and len(d['rows'])==6
assert sum(x['baselineExact'] for x in d['rows'])==2 and sum(x['candidateExact'] for x in d['rows'])==5
assert d['strictDifferences']==['repeat-key']
for name in ['checker-name-direct-01','checker-name-direct-02']:
 r=read(base/name/'report.json');assert not r['complete'] and r['error']
report={'kind':'phase16-template-naming-audit','complete':True,'scopedNumberingGate':True,'fullMemoIdentityGate':False,'inputs':inputs+[ident(base/'checker-source-05/manifest.json'),ident(Path(__file__))],'priorObservations':{'count':84,'primitiveAgreement':84,'exact':25,'strictDifferences':59,'changed':['check/template_inst_cycle.bend']},'pairedNameControls':{'count':12,'primitiveAgreement':12,'exact':6,'strictDifferences':6,'changed':sorted(changed)},'materializedInstances':{'controls':6,'baselineExact':2,'candidateExact':5,'inheritedStrictDifference':'repeat-key'},'retainedFailures':['checker-name-direct-01: raw parse without module scoping','checker-name-direct-02: stopped on real inherited repeat-key mismatch'],'scope':'Per-template ordinal correction passes its scoped gate. Repeated source-position-dependent memo entries remain a failing, separately planned boundary; not full conformance or speed validation.'}
(out/'report.json').write_text(json.dumps(report,indent=2)+'\n');print(json.dumps({k:report[k] for k in ['complete','scopedNumberingGate','fullMemoIdentityGate','priorObservations','materializedInstances']}))
