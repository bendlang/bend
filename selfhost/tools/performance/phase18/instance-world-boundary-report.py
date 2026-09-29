"""Close the immutable Stage1 public-boundary gates without mixing timing images."""
from pathlib import Path
import hashlib,json,re
ROOT=Path(__file__).resolve().parents[4];phase=ROOT/'selfhost/build/phase18'
def read(p):return json.loads(p.read_text())
def ident(p):return {'file':str(p),'bytes':p.stat().st_size,'sha256':hashlib.sha256(p.read_bytes()).hexdigest()}
def count(root):
    names=read(root/'src/compiler.json')['modules'];texts=[(root/n).read_text() for n in names];s=''.join(texts)
    return {'modules':len(names),'physicalLines':sum(len(t.splitlines()) for t in texts),'nonblankLines':sum(bool(l.strip()) for t in texts for l in t.splitlines()),'bytes':sum((root/n).stat().st_size for n in names),'definitions':len(re.findall(r'^def ',s,re.M)),'laws':len(re.findall(r'^law ',s,re.M)),'types':len(re.findall(r'^type ',s,re.M))}
source=read(phase/'instance-world-source-06/manifest.json')
names=['instance-world-public-02','instance-world-direct-02','instance-world-demand-02','instance-world-candidate-paired-02','instance-world-memo-02']
reports={n:read(phase/n/'report.json') for n in names}
assert all(r['complete'] and r['pass'] for r in reports.values())
assert [len(reports[n]['rows']) for n in [names[0],names[1],names[2],names[4]]]==[18,37,5,8]
pairNames=['instance-world-parent-paired-01','instance-world-candidate-paired-02']
pairs=[read(phase/n/'selected/paired.json') for n in pairNames]
assert len(pairs[0]['rows'])==len(pairs[1]['rows'])==22
assert all((a['id'],a['lane'],a['candidate'],a['reference'])==(b['id'],b['lane'],b['candidate'],b['reference']) for a,b in zip(*[x['rows'] for x in pairs]))
gaps=[{'id':r['id'],'lane':r['lane']} for r in pairs[1]['rows'] if not r['exactAgreement']]
assert len(gaps)==2
old=read(phase/'instance-world-public-01/report.json');assert old['complete'] and not old['pass']
assert [r['name'] for r in old['rows'] if not r['pass']]==['diagnostic-required-error-before-term']
build=read(phase/'instance-world-build-06/build.json');assert build['complete'] and build['artifactKind']=='derived-b1'
parent=ROOT/'selfhost/build/phase17/find-worker-source-01/project';project=phase/'instance-world-source-06/project'
before=count(parent);after=count(project);delta={k:after[k]-before[k] for k in before}
assert {k:delta[k] for k in source['delta']}==source['delta']
inputs=[Path(__file__),ROOT/'implementation/phase18/instance-world-public-boundary.md',phase/'instance-world-source-06/manifest.json',phase/'instance-world-source-06/source.patch',phase/'instance-world-source-06/binding.patch',parent/'src/compiler.json',project/'src/compiler.json',phase/'instance-world-build-06/build.json',phase/'instance-world-build-06/attempt.json',phase/'instance-world-public-01/report.json',phase/'instance-world-build-05/build.json',phase/'instance-world-build-05/bootstrap/stderr',ROOT/'implementation/phase18/instance-world-cost.json']+[phase/n/'report.json' for n in names]+[phase/n/'selected'/f for n in pairNames for f in ['paired.json','candidate.json','reference.json']]
inputs+=sorted((ROOT/'design/phase18').glob('instance-world-*.md'))
report={'kind':'phase18-world-stable-public-boundary','complete':True,'pass':True,'installed':False,'semanticInstantiation':False,'candidateAPI':build['api'],'sourceParent':str(parent),'sourceProject':str(project),'productionCountScope':'Only exact src/compiler.json module membership; historical source-preparation manifests count all copied Bend files, whose unchanged extras cancel in the delta.','productionBefore':before,'productionAfter':after,'sourceDelta':delta,'changedFiles':source['changes'],'publicExports':71,'publicResult':'KSpecialized {book,error:KChecked{term,typ,uses,error}} unchanged; internal KChecking adds world/consumed','gates':{'genuineCheckedB1Default36':True,'inheritedDefaultStrictDifferences':2,'publicRawShapeAndDemand':18,'directTransportAndDemand':42,'pairedCompleteParentEquality':22,'memoInstanceNames':8,'strictTSGapsUnchanged':gaps,'overlap':'Eight whole-program/annotation controls are included in direct37 and use the memo8 fixtures; counts are not unique corpus coverage.'},'attempts':[{'source':'03','result':'Scoped language equivalence and neutral cost, but raw KSpecialized leaked six-field internal result; not promotable.'},{'source':'04','result':'Genuine checked/default36 passes; public18 completed17pass1fail on required error-before-term demand.'},{'source':'05','result':'Pinned bootstrap parser refuses match after using its binder; no API and no public probe produced.'},{'source':'06','result':'Separate error and term projections preserve required demand and pass all listed gates.'}],'cost':{'measuredSource':'03 only','decision':'Neutral screening, not a speedup; source06 adapter has no controlled timing measurement.','source03Report':str(ROOT/'implementation/phase18/instance-world-cost.json')},'limitations':['Stage1 changes representation only; actual consumed counts remain zero.','Known/Deferred fresh state is never resolved in Stage1.','Source body publication and postcheck specialization order are unchanged.','Immutable Bend payload results, unused-field demand and first-failure order are checked; repeated reads of a stateful JS getter are not an equivalence contract.','No full frontend, backend, self-hosted fixed point or production installation claim.'],'evidence':[ident(p) for p in inputs]}
out=ROOT/'implementation/phase18/instance-world-public-boundary.json';assert not out.exists();out.write_text(json.dumps(report,indent=2)+'\n')
print(json.dumps({'complete':True,'pass':True,'api':build['api']['sha256'],'counts':after,'delta':delta,'public':18,'transport':42,'paired':22,'memo':8}))
