"""Preserve failed01; fix explicit signatures and minted-source self descent."""
from pathlib import Path
import shutil,json,hashlib,difflib,re
ROOT=Path(__file__).resolve().parents[4];PHASE=ROOT/'selfhost/build/phase19';OLD=PHASE/'instance-source-01/project';OUT=PHASE/'instance-source-03';OUT.mkdir();P=OUT/'project';shutil.copytree(OLD,P)
p=P/'src/check/kernel.bend';old=p.read_text();s=old
heads={
'tele_check_head(e, ctx, tel, h, rest, dem)':'tele_check_head(+e: KEnv, +ctx: List<&2,KTerm>, +tel: KTerm, +h: KTerm, +rest: List<&2,KTerm>, +dem: U32) -> KChecking',
'tele_check_static(e, ctx, tel, args, dem)':'tele_check_static(+e: KEnv, +ctx: List<&2,KTerm>, +tel: KTerm, +args: List<&2,KTerm>, +dem: U32) -> KChecking',
'check_mat_filled(e, ctx, t, dem, ty, a, ctr, tel)':'check_mat_filled(+e: KEnv, +ctx: List<&2,KTerm>, +t: KTerm, +dem: U32, +ty: KTerm, +a: KTerm, +ctr: KDef, +tel: KTerm) -> KChecking'}
for a,b in heads.items():assert s.count('def '+a+':')==1;s=s.replace('def '+a+':','def '+b+':')
assert s.count('self_pending(d, body)')==1
s=s.replace('lhs, self_pending(d, body), tele_quantities','lhs, kc(U32, U32.is_gt(depth, 0) && Bool.not(du(d)), u => U32.sub(da(d), dx(d)), u => self_pending(d, body)), tele_quantities')
assert s!=old;p.write_text(s)
(OUT/'correction.patch').write_text(''.join(difflib.unified_diff(old.splitlines(True),s.splitlines(True),fromfile='source01/src/check/kernel.bend',tofile='source03/src/check/kernel.bend')))
config=json.loads((PHASE/'instance-source-01/workflow.json').read_text());config['project']=str(P);(OUT/'workflow.json').write_text(json.dumps(config,indent=2)+'\n')
inputs=[Path(__file__),ROOT/'design/phase19/instance-first-corrections.md',PHASE/'instance-source-01/manifest.json',PHASE/'instance-source-02/preparation-failure.json',PHASE/'instance-build-01/build.json',PHASE/'instance-build-01/bootstrap/stderr']
(OUT/'manifest.json').write_text(json.dumps({'kind':'phase19-first-prototype-correction','complete':True,'frozen':True,'parent':str(OLD),'project':str(P),'change':'Three explicit signatures and runtime lhs pending count for safe minted instances.','members':{str(f.relative_to(P)):{'sha256':hashlib.sha256(f.read_bytes()).hexdigest(),'bytes':f.stat().st_size,'mode':f.stat().st_mode&0o777}for f in sorted(P.rglob('*'))if f.is_file()},'inputs':[{'file':str(f),'sha256':hashlib.sha256(f.read_bytes()).hexdigest()}for f in inputs],'installed':False},indent=2)+'\n');print(json.dumps({'complete':True,'project':str(P)}))
