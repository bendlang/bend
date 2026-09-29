from pathlib import Path
import json,hashlib
root=Path.cwd();base=root/'selfhost/build/phase16';out=base/'checker-audit-05';out.mkdir();inputs=[]
def ident(p):return {'file':str(p.resolve()),'sha256':hashlib.sha256(p.read_bytes()).hexdigest()}
def read(p):inputs.append(ident(p));return json.loads(p.read_text())
def rows(name,count):
 p=base/name;assert read(p/'report.json')['complete'];r=read(p/'selected/paired.json');assert len(r['rows'])==count and not r['missing'];assert all(x['semanticAgreement'] for x in r['rows'])
 for side in ['reference','candidate']:
  x=read(p/'selected'/f'{side}.json');assert x['finished'] and len(x['results'])==count and not x['changedInputs'] and not x['identity']['adapterChangedDuringRun'] and not x['identity']['changedArtifacts'];assert all(not y['errors'] and not y['stats']['timeouts'] and not y['stats']['failures'] for y in x['workers'])
 return {x['id']:x for x in r['rows']}
a=rows('checker-all-05',84);b=rows('checker-all-06',84);assert {k for k in b if a[k]['candidate']!=b[k]['candidate']}=={'comptime/err_grow_double.bend'}
assert sum(x['exactAgreement'] for x in b.values())==25
u=rows('checker-key-baseline-01',22);v=rows('checker-key-candidate-01',22);assert {k for k in v if u[k]['candidate']!=v[k]['candidate']}=={'comptime/err_grow_double.bend','p16-checker-names/prior-repeated-instance.bend'}
assert 'Location: grow~9' in b['comptime/err_grow_double.bend']['reference']['diagnostic'] and 'Location: grow~10' in b['comptime/err_grow_double.bend']['candidate']['diagnostic']
d=read(base/'checker-key-direct-02/report.json');assert d['complete'] and d['pass'] and d['exactByCandidate']==[7,10,16]
e=read(base/'checker-key-direct-03/report.json');assert e['complete'] and not e['pass'] and e['exactByCandidate']==[9,12,17] and e['strictDifferences']==['u32-literal-vs-constructor']
l=read(base/'checker-key-length-02/report.json');assert l['complete'] and l['pass'] and [x['firstOverLimit'] for x in l['implementations']]==[10,10,11]
s=read(base/'checker-key-shape-02/report.json');assert s['complete'] and s['pass'] and len(s['rows'])==22
report={'kind':'phase16-template-key-rejection-audit','complete':True,'promotionEligible':False,'inputs':inputs+[ident(base/'checker-source-06/manifest.json'),ident(Path(__file__))],'priorObservations':{'count':84,'primitiveAgreement':84,'exact':25,'strictDifferences':59,'newFirstErrorRegression':'comptime/err_grow_double.bend'},'initialDirectControls':{'count':16,'baselineExact':7,'ordinalOnlyExact':10,'scopedKeyExact':16,'instancesBefore':34,'instancesAfter':28},'expandedDirectControls':{'count':18,'baselineExact':9,'ordinalOnlyExact':12,'scopedKeyExact':17,'lostLiteralIdentity':'u32-literal-vs-constructor'},'boundary':{'pinnedFirstOverLimit':10,'ordinalOnlyFirstOverLimit':10,'scopedKeyFirstOverLimit':11,'exactShapeProjections':22},'retainedFailures':['checker-key-direct-01: unannotated constructor cannot infer in parallel let','checker-key-length-01: read uncompleted caller body after pinned validation replaced it with a declaration','checker-key-shape-01: Python default recursion limit reached'],'conclusion':'Reject source06 despite fewer duplicate instances. Exact upstream keys require literal syntax identity retained by the core, and their UTF16 size contract cannot be approximated or cutoff-tuned. Source05 numbering remains independent.'}
(out/'report.json').write_text(json.dumps(report,indent=2)+'\n');print(json.dumps({k:report[k] for k in ['complete','promotionEligible','priorObservations','expandedDirectControls','boundary']}))
