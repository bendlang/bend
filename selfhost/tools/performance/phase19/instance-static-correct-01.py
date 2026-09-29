"""Before first build: avoid an unneeded match fresh scan and duplicate argument slices."""
from pathlib import Path
import difflib,hashlib,json,re
ROOT=Path(__file__).resolve().parents[4];P=ROOT/'selfhost/build/phase19/instance-source-01/project';OUT=ROOT/'selfhost/build/phase19/instance-static-edit-01'
def fn(s,name,new):
 m=re.search(r'^def '+name+r'\b',s,re.M);assert m,name
 e=re.search(r'^(?:@unsafe|def |law |type )',s[m.end():],re.M);end=m.end()+e.start() if e else len(s)
 return s[:m.start()]+new.strip()+'\n\n'+s[end:]
paths=['src/check/kernel.bend','src/check/specialize.bend'];before={n:(P/n).read_text()for n in paths};files=dict(before)
s=files[paths[0]]
s=fn(s,'mat_lhs','''def mat_lhs(e, name, tel, n, avoid):
  kc(KEnv, U32.is_eq(cp(e), 0), u => e, u => ki_lhs(e, name, tel, n, kc(U32, U32.is_eq(n, 0), u => 0, u => U32.add(1, kw_temp_floor(cw(e), Con{cl(e), Con{tel, avoid}})))))''')
s=fn(s,'check_mat_filled','''def check_mat_filled(e, ctx, t, dem, ty, a, ctr, tel):
  ki_match_bound(e, ctx, t, dem, ty, a, ctr, tel, kc(U32, U32.is_eq(cp(e), 0) || U32.is_eq(da(ctr), 0), u => 0, u => kw_temp_floor(cw(e), Con{cl(e), Con{tel, Con{t, Con{ty, ctx}}}})))''')
s=s.replace('check(mat_lhs(e, nm(t), tel, da(ctr), Con{t, Con{ty, ctx}}), ctx, kid(t, 0), dem, mat_goal(cb(e), ty, tel, da(ctr), nm(t), Nil{}))','check(kc(KEnv, U32.is_eq(cp(e), 0), u => e, u => ki_lhs(e, nm(t), tel, da(ctr), U32.add(bound, 1))), ctx, kid(t, 0), dem, mat_goal(cb(e), ty, tel, da(ctr), nm(t), Nil{}))')
files[paths[0]]=s
s=files[paths[1]]
s=fn(s,'sp_live_checked','''def sp_live_checked(+e: KEnv, +ctx: List<&2,KTerm>, +head: KTerm, +sp: List<&2,KTerm>, +d: KDef, +r: KChecking) -> KChecking:
  kc(KChecking, good(r), u => sp_live_args(ke_world(e, rw(r)), ctx, head, sp, d, sp_take(sp, dx(d))), u => r)''')
s+='''@unsafe
def sp_live_args(+e: KEnv, +ctx: List<&2,KTerm>, +head: KTerm, +sp: List<&2,KTerm>, +d: KDef, +xs: List<&2,KTerm>) -> KChecking:
  sp_live_key(e, ctx, head, sp, d, xs, sp_keys(xs))
'''
files[paths[1]]=s
OUT.mkdir();rows=[]
for n,s in files.items():
 old=before[n];(P/n).write_text(s);(OUT/(n.replace('/','_')+'.patch')).write_text(''.join(difflib.unified_diff(old.splitlines(True),s.splitlines(True),fromfile='before/'+n,tofile='after/'+n)));rows.append({'file':n,'before':hashlib.sha256(old.encode()).hexdigest(),'after':hashlib.sha256(s.encode()).hexdigest()})
(OUT/'manifest.json').write_text(json.dumps({'kind':'phase19-prebuild-static-correction','complete':True,'files':rows,'toolSha256':hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),'finding':'Initial draft computed match fresh bounds even with no pending lhs/no generated IDs. This edit retains prior demand and reuses the bound once; no compiler job preceded it.'},indent=2)+'\n');print(json.dumps({'complete':True}))
