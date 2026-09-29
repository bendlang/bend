"""Bind closed independent structural gates and owned preservation scope."""
from pathlib import Path
from collections import Counter
import hashlib,json
R=Path(__file__).resolve().parents[4];B=R/'selfhost/build/phase21';O=R/'implementation/phase21/group-range-structure.json';assert not O.exists()
identity=lambda p:{'file':str(p.resolve()),'sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'bytes':p.stat().st_size}
roots=['group-range-structure-controls-01','group-range-structure-parent-01','group-range-structure-candidate-01','group-range-structure-ann-controls-01','group-range-structure-ann-parent-01','group-range-structure-candidate-02','group-range-structure-ann-candidate-02','group-range-structure-ann-audit-02']
runs=[];envelopes=0
for name in ['group-range-structure-candidate-02','group-range-structure-ann-candidate-02']:
 p=B/name/'report.json';r=json.loads(p.read_text());assert r['complete']and r['pass']
 counts=Counter(d['tag']for x in r['rows']for d in x['differences']['ranges'])
 assert all(not x['differences']['nonrange']and x['acceptanceSame']and x.get('legacyOriginsAbsent',True)for x in r['rows'])
 for f in (B/name).glob('*.json'):
  x=json.loads(f.read_text())
  if isinstance(x,dict)and'images'in x and len(x['images'])==2 and'book'in x['images'][0]:
   a,b=x['images'];assert{k:v for k,v in a.items()if k not in['book','error']}=={k:v for k,v in b.items()if k not in['book','error']},f;envelopes+=1
 runs.append({'report':identity(p),'observations':len(r['rows']),'changedRows':sum(bool(x['differences']['ranges'])for x in r['rows']),'rangePaths':sum(counts.values()),'rangeTags':dict(counts),'legacyObservations':sum('legacy'in x['mode']for x in r['rows'])})
ap=B/'group-range-structure-ann-audit-02/report.json';a=json.loads(ap.read_text());assert a['complete']and a['pass']and a['exactPositiveObservations']==30
paths=[R/'design/phase21/group-range-structure.md',R/'design/phase21/group-range-structure-ann.md',R/'implementation/phase21/group-range-structure-source01.md',R/'implementation/phase21/group-range-structure-source01.json',R/'implementation/phase21/group-range-structure.md']
paths +=sorted((R/'selfhost/tools/performance/phase21').glob('group-range-structure-*'))
paths +=[B/(n+'.log')for n in roots if(B/(n+'.log')).is_file()]
source=B/'group-range-source-02/manifest.json';attempt=B/'group-range-build-02/attempt.json';m=json.loads(attempt.read_text())
report={'kind':'phase21-independent-source02-structure-review','complete':True,'boundedStructureGatePass':True,'compilerSourceEdited':False,'promotionDecisionOwnedByRoot':True,'observations':sum(x['observations']for x in runs),'legacyAllAbsent':True,'legacyObservations':sum(x['legacyObservations']for x in runs),'nonrangeBookDifferences':0,'acceptanceChanges':0,'savedWholeResultEnvelopesUnchanged':envelopes,'exactPinnedAnnObservations':30,'negativeAnnFixturesRetained':2,'runs':runs,'annotationAudit':identity(ap),'source':identity(source),'attempt':identity(attempt),'api':identity(Path(m['api']['file'])),'evidenceRoots':[str(B/x)for x in roots],'limitations':['No complete compiler-workload graph serialization/comparison.','Range-path counts include repeated Base terms across independent observations.','Pin constructor-group acceptance/checkpoint gaps are inherited and are not fixed by this candidate.','Exact annotation claim is15successful fixtures at raw/lowered boundaries; rejected neighbors are not counted as annotation coordinates.'],'inputs':[identity(x)for x in paths]}
O.write_text(json.dumps(report,indent=2)+'\n');paths.append(O)
freeze=B/'group-range-structure-owner-freeze-01.json';assert not freeze.exists()
freeze.write_text(json.dumps({'kind':'phase21-structure-owner-freeze','closed':True,'files':[identity(x)for x in paths],'evidenceRoots':report['evidenceRoots'],'dependencyManifests':[identity(source),identity(attempt)],'protected75Policy':'No compiler/live/Phase6 source edits by this owner.'},indent=2)+'\n');print(json.dumps({'report':str(O),'freeze':str(freeze),'files':len(paths),'roots':len(roots),'observations':report['observations'],'envelopes':envelopes}))
