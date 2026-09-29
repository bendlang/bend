"""Frozen observed let close-order/site correction; preserve source03."""
from pathlib import Path
import json,hashlib,shutil,difflib
ROOT=Path(__file__).resolve().parents[4];PHASE=ROOT/'selfhost/build/phase19';OLD=PHASE/'instance-source-03/project';OUT=PHASE/'instance-source-04';OUT.mkdir();P=OUT/'project';shutil.copytree(OLD,P)
p=P/'src/check/kernel.bend';old=p.read_text();s=old
head='law check_let_done:\n  for +e: KEnv\n  for +ctx: List<&2,KTerm>\n  for +r: KChecking\n  for +bs: List<&2, KTerm>\n  for +us: List<&2, KTerm>\n'
assert s.count(head)==1;s=s.replace(head,head+'  for +site: KTerm\n')
a='check_let_done(e, outer, check(e, ctx, let_cells(h, bindings), dem, ty), bindings, us)'
b='check_let_done(e, outer, check(e, ctx, let_cells(h, bindings), dem, ty), ki_reverse_terms(bindings, Nil{}), us, kc(KTerm, U32.is_eq(kb(site), 0), u => kid(site, 0), u => site))'
assert s.count(a)==1;s=s.replace(a,b)
a='def check_let_done(e, ctx, r, bs, us):';assert s.count(a)==1;s=s.replace(a,'def check_let_done(e, ctx, r, bs, us, site):')
a='      kc(KChecking, U32.is_gt(uses_get(cs(r), ix(h)), qt(h)), u => dg_trace(e, ctx, h, cy(r), kr_from(r, dg_quant_error(rw(r), "let binder consumed more than allowed", nm(h), qt(h), uses_get(cs(r), ix(h))))), u => kc(KChecking, good(r), u => check_let_done(e, ctx, KChecking{ct(r), cy(r), uses_del(cs(r), ix(h)), "", rw(r), rx(r)}, t, us), u => r))'
b='      kc(KChecking, good(r), u => kc(KChecking, U32.is_gt(uses_get(cs(r), ix(h)), qt(h)), u => dg_trace(e, ctx, site, cy(r), kr_from(r, dg_quant_error(rw(r), "let binder consumed more than allowed", nm(h), qt(h), uses_get(cs(r), ix(h))))), u => check_let_done(e, ctx, KChecking{ct(r), cy(r), uses_del(cs(r), ix(h)), "", rw(r), rx(r)}, t, us, site)), u => r)'
assert s.count(a)==1;s=s.replace(a,b);p.write_text(s)
(OUT/'correction.patch').write_text(''.join(difflib.unified_diff(old.splitlines(True),s.splitlines(True),fromfile='source03/src/check/kernel.bend',tofile='source04/src/check/kernel.bend')))
config=json.loads((PHASE/'instance-source-03/workflow.json').read_text());config['project']=str(P);(OUT/'workflow.json').write_text(json.dumps(config,indent=2)+'\n')
inputs=[Path(__file__),ROOT/'design/phase19/instance-let-closure.md',ROOT/'design/phase19/instance-let-observations.md',PHASE/'instance-source-03/manifest.json',PHASE/'instance-let-paired-01/report.json',PHASE/'instance-let-ranges-01/report.json',PHASE/'instance-let-ranges-02/report.json',PHASE/'instance-let-controls-02/manifest.json']
(OUT/'manifest.json').write_text(json.dumps({'kind':'phase19-let-close-order-correction','complete':True,'frozen':True,'parent':str(OLD),'project':str(P),'change':'Source-order usage closure only after child success; exact original Local/Do source site.','netPhysicalLines':len(s.splitlines())-len(old.splitlines()),'members':{str(f.relative_to(P)):{'sha256':hashlib.sha256(f.read_bytes()).hexdigest(),'bytes':f.stat().st_size,'mode':f.stat().st_mode&0o777}for f in sorted(P.rglob('*'))if f.is_file()},'inputs':[{'file':str(f),'sha256':hashlib.sha256(f.read_bytes()).hexdigest()}for f in inputs],'installed':False},indent=2)+'\n');print(json.dumps({'complete':True,'project':str(P)}))
