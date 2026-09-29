"""Compose only two already-checked lookup deltas; never install or time."""
from pathlib import Path
import hashlib,json,difflib,shutil,sys
R=Path(__file__).resolve().parents[4];P=R/'selfhost/build/phase22'
control=Path(sys.argv[1]).resolve();c=json.loads(control.read_text());assert c.get('complete') and c.get('pass')
base=P/'context-build-12';ctor=P/'constructor-bool-build-01';indexed=P/'context-build-14';out=P/'context-source-16'
def identity(p):
 p=Path(p).resolve();return {'file':str(p),'sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'bytes':p.stat().st_size}
def members(attempt):
 a=json.loads((attempt/'attempt.json').read_text());result={}
 for row in a['snapshot']['sources']:
  p=Path(row['frozen']['file']);rel=str(p.relative_to(a['snapshot']['root']));assert identity(p)['sha256']==row['frozen']['sha256'];result[rel]=p
 assert len(result)==215
 build=json.loads((attempt/'build.json').read_text());v=json.loads((attempt/'validation-001/report.json').read_text());assert build['complete'] and v['complete'] and v['pass'] and v['strictExact'] and v['selected']['exactDifferences']==0
 assert identity(Path(a['api']['file']))['sha256']==a['api']['sha256']
 return a,result
ba,bm=members(base);ca,cm=members(ctor);ia,im=members(indexed)
assert set(bm)==set(cm)==set(im)
assert ba['api']['sha256']=='a80737cd74e8b3e78b07006580ed3aded060c530b3d67af032db81a17fa3f404'
assert [x['api']['sha256']for x in c['parts']]==[ba['api']['sha256'],ia['api']['sha256']]
assert ca['api']['sha256']=='4c81ab1174cecd656ddde43b589fdb23540706b005ae8aa821722151e5a82490'
assert ia['api']['sha256']=='9a3b9e09095caca347c2aea7b653048df274c3ec693883ccf5938b7b0e439c5a'
def changed(left,right):return [name for name in sorted(left)if left[name].read_bytes()!=right[name].read_bytes()]
assert changed(bm,cm)==['src/front/validate.bend']
assert changed(bm,im)==['src/front/contextual.bend']
ctor_control=P/'context-controls-ctor-demand-02/report.json';cc=json.loads(ctor_control.read_text());assert cc['complete'] and cc['pass'] and cc['rawExactPass']
assert [x['api']['sha256']for x in cc['lanes']]==[ba['api']['sha256'],ca['api']['sha256']]
proof=P/'context-template-index-proof-01/report.json';pr=json.loads(proof.read_text());assert pr['complete'] and pr['pass']
inputs=[Path(__file__),R/'design/phase22/guarded-lookup-union.md',control,ctor_control,proof]
for d in [base,ctor,indexed]:inputs.extend([d/'attempt.json',d/'build.json',d/'validation-001/report.json'])
for d in [P/'context-source-14',P/'context-source-15']:inputs.append(d/'manifest.json')
fixed=[identity(p)for p in inputs]
out.mkdir();project=out/'project';chosen=dict(im);chosen['src/front/validate.bend']=cm['src/front/validate.bend']
rows=[];changes=[]
for name,p in sorted(chosen.items()):
 target=project/name;target.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(p,target);rows.append({'path':name,**identity(target)})
 if bm[name].read_bytes()!=target.read_bytes():
  before=bm[name].read_text();after=target.read_text();patch=out/(name.replace('/','_')+'.patch');patch.write_text(''.join(difflib.unified_diff(before.splitlines(True),after.splitlines(True),fromfile='parent/'+name,tofile='candidate/'+name)))
  changes.append({'path':name,'physicalLineDelta':len(after.splitlines())-len(before.splitlines()),'byteDelta':len(target.read_bytes())-len(bm[name].read_bytes()),'patch':identity(patch)})
assert [x['path']for x in changes]==['src/front/contextual.bend','src/front/validate.bend']
assert [identity(p)for p in inputs]==fixed
(out/'manifest.json').write_text(json.dumps({'kind':'phase22-two-reviewed-lookup-delta-union','complete':True,'installed':False,'parentApi':ba['api'],'constructorApi':ca['api'],'templateCountApi':ia['api'],'project':str(project),'parentMembership':[{'path':n,**identity(p)}for n,p in sorted(bm.items())],'candidateMembership':rows,'changes':changes,'inputs':fixed,'scope':'Exactly source15 indexed dx projection plus source14 constructor Bool worker on common source13 parent; no new optimization or host change.'},indent=2)+'\n')
(out/'workflow.json').write_text(json.dumps({'project':str(project),'upstream':ia['config']['upstream'],'profile':'equality','cpu':'3','jobs':1,'strictExact':True},indent=2)+'\n')
print(json.dumps({'source':str(out),'members':len(rows),'changes':changes}))
