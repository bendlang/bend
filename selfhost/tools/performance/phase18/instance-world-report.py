"""Bind the closed representation correctness evidence; timing is a separate gate."""
from pathlib import Path
import hashlib,json
ROOT=Path(__file__).resolve().parents[4];phase=ROOT/'selfhost/build/phase18';out=ROOT/'implementation/phase18'
def read(p):return json.loads(p.read_text())
def ident(p):return {'file':str(p),'bytes':p.stat().st_size,'sha256':hashlib.sha256(p.read_bytes()).hexdigest()}
source=read(phase/'instance-world-source-03/manifest.json')
names=['instance-world-parent-paired-01','instance-world-candidate-paired-01','instance-world-paired-equivalence-01','instance-world-direct-01','instance-world-demand-01','instance-world-memo-01']
reports={n:read(phase/n/'report.json') for n in names}
assert all(r['complete'] and r['pass'] for r in reports.values())
assert len(reports['instance-world-direct-01']['rows'])==37
assert len(reports['instance-world-demand-01']['rows'])==5
assert len(reports['instance-world-memo-01']['rows'])==8
paired=[read(phase/n/'selected/paired.json') for n in names[:2]]
assert len(paired[0]['rows'])==len(paired[1]['rows'])==22
assert all(a['candidate']==b['candidate'] and a['reference']==b['reference'] for a,b in zip(*[x['rows'] for x in paired]))
assert sum(not x['exactAgreement'] for x in paired[1]['rows'])==2
inputs=[Path(__file__),ROOT/'design/phase18/instance-world-representation.md',ROOT/'design/phase18/representation_cost.md',phase/'instance-world-source-03/manifest.json',phase/'instance-world-source-03/source.patch',phase/'instance-world-build-01/build.json',phase/'instance-world-build-01/bootstrap/stderr',phase/'instance-world-build-02/build.json',phase/'instance-world-build-03/build.json',phase/'instance-world-build-03/attempt.json']+[phase/n/'report.json' for n in names]+[phase/n/'selected'/f for n in names[:2] for f in ['paired.json','candidate.json','reference.json']]
report={'kind':'phase18-world-representation-correctness','complete':True,'pass':True,'installed':False,'semanticInstantiation':False,'sourceParent':source['parent'],'sourceProject':source['project'],'candidateAPI':read(phase/'instance-world-build-03/build.json')['api'],'sourceDelta':source['delta'],'changedFiles':source['changes'],'newConcepts':['checker world retaining source book/memo/fresh state','explicit known/deferred fresh-state availability','returned world and consumed-count transport; no count consumption yet'],'retainedConcepts':['existing postcheck specializer and its state/visitor','existing source and program event order','existing diagnostic renderer and public ABIs'],'gates':{'checkedB1':'build03 genuine checked + maintained v5 + default36 pass; two inherited strict differences','pairedWholeOutcomeEquivalence':22,'strictTSDifferencesUnchanged':2,'directTransportAndDemand':42,'publicMemoNames':8,'wholeProgramAndAnnotation':8,'wholeProgramNote':'The eight whole-program/annotation rows are included in the 37 direct rows; counts overlap.'},'attempts':[{'attempt':'build01','result':'checked bootstrap refused: KEnv local constructor binding needed explicit annotation'},{'attempt':'build02','result':'checked/v5/default36 pass; independent review found nonzero metadata transport misses before direct controls'},{'attempt':'build03','result':'42 direct,22 parent equivalence,8 memo checks pass'}],'timing':{'status':'not run by this owner','decision':'pending root-coordinated matrix; correctness does not establish acceptable cost'},'evidence':[ident(p) for p in inputs]}
p=out/'instance-world-correctness.json';assert not p.exists();p.write_text(json.dumps(report,indent=2)+'\n');print(json.dumps({'complete':True,'pass':True,'delta':source['delta'],'direct':42,'paired':22,'memo':8}))
