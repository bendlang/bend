"""First owned Phase19 edit: explicit output/fresh-root world interfaces only."""
from pathlib import Path
import difflib,hashlib,json,re
ROOT=Path(__file__).resolve().parents[4];OUT=ROOT/'selfhost/build/phase19/instance-world-edit-01';PROJECT=ROOT/'selfhost/build/phase19/instance-source-01/project'
def fn(s,name,new):
    m=re.search(r'^def '+name+r'\b',s,re.M);assert m,name
    e=re.search(r'^(?:@unsafe|def |law |type )',s[m.end():],re.M);end=m.end()+e.start() if e else len(s)
    return s[:m.start()]+new.strip()+'\n\n'+s[end:]
path=PROJECT/'src/check/kernel.bend';old=path.read_text();s=old
assert 'KFreshDeferred{}' in s
s=s.replace('KFreshDeferred{}','KFreshDeferred{+roots: List<&2,KTerm>}',1)
s=s.replace('KWorld{+book: List<&2,KDef>, +memo: List<&2,KSpecMemo>, +fresh: KWorldFresh}','KWorld{+book: List<&2,KDef>, +memo: List<&2,KSpecMemo>, +fresh: KWorldFresh, +checked: List<&2,KDef>}')
s=s.replace('case KWorld{book, memo, fresh}:','case KWorld{book, memo, fresh, checked}:')
s=s.replace('KWorld{book, Nil{}, KFreshDeferred{}}','KWorld{book, Nil{}, KFreshDeferred{Nil{}}, Nil{}}')
s=s.replace('KWorld{book, kw_memo(world), kw_fresh(world)}','KWorld{book, kw_memo(world), kw_fresh(world), kw_checked(world)}')
s=s.replace('# Stage1 world transport only: no deferred fresh bound is resolved here.','# Source book and completed output are separate. Deferred roots are not traversed until mint.')
s+='''@unsafe
def kw_checked(+world: KWorld) -> List<&2,KDef>:
  match world:
    case KWorld{book, memo, fresh, checked}: checked

@unsafe
def kw_seed(+book: List<&2,KDef>, +bound: U32) -> KWorld:
  KWorld{book, Nil{}, kc(KWorldFresh, U32.is_eq(bound, 4294967295), u => KFreshDeferred{Nil{}}, u => KFreshKnown{U32.add(bound, 1)}), Nil{}}

@unsafe
def kw_with_checked(+world: KWorld, +checked: List<&2,KDef>) -> KWorld:
  KWorld{kw_book(world), kw_memo(world), kw_fresh(world), checked}

@unsafe
def kw_put_checked(+world: KWorld, +d: KDef) -> KWorld:
  kw_with_checked(world, Con{d, kw_checked(world)})

@unsafe
def ke_world(+e: KEnv, +world: KWorld) -> KEnv:
  KEnv{world, cn(e), cl(e), cp(e), cq(e), cu(e), cd(e)}

@unsafe
def kw_owner(+world: KWorld, +ty: KTerm, +body: KTerm) -> KWorld:
  kw_owner_fresh(world, ty, body, kw_fresh(world))

@unsafe
def kw_owner_fresh(+world: KWorld, +ty: KTerm, +body: KTerm, +fresh: KWorldFresh) -> KWorld:
  match fresh:
    case KFreshKnown{next}: world
    case KFreshDeferred{roots}: KWorld{kw_book(world), kw_memo(world), KFreshDeferred{Con{ty, Con{body, roots}}}, kw_checked(world)}

@unsafe
def check_definition_body(+world: KWorld, +d: KDef, +depth: U32) -> KChecking:
  kw_restore_definition(world, d, check_template_definition(kw_owner(world, dt(d), dv(d)), d, dt(d), dv(d), ref(dn(d)), dx(d), depth))
'''
s=fn(s,'check_definition_type','''def check_definition_type(book, d, e, r):
  kc(KChecking, good(r), u => kc(KChecking, String.eq(dk(d), "ADT"), u => check_adt_declaration(ke_world(e, rw(r)), d),
   u => kc(KChecking, String.eq(tg(dv(d)), "Absent"), u => r, u => kc(KChecking, String.eq(tg(dv(d)), "Foreign"), u => check_foreign(rw(r), d, cd(e)), u => check_definition_body(rw(r), d, cd(e))))), u => r)
''')
OUT.mkdir();(OUT/'kernel.patch').write_text(''.join(difflib.unified_diff(old.splitlines(True),s.splitlines(True),fromfile='before/src/check/kernel.bend',tofile='after/src/check/kernel.bend')))
path.write_text(s)
inputs=[Path(__file__),ROOT/'design/phase19/instance-interfaces.md',ROOT/'design/phase19/instance-output-order.md']
(OUT/'manifest.json').write_text(json.dumps({'kind':'phase19-world-interface-edit','complete':True,'files':[{'file':str(path),'before':hashlib.sha256(old.encode()).hexdigest(),'after':hashlib.sha256(s.encode()).hexdigest()}],'inputs':[{'file':str(p),'sha256':hashlib.sha256(p.read_bytes()).hexdigest()}for p in inputs],'scope':'Intermediate shared source edit; no build. Other files are still being migrated by their owners.'},indent=2)+'\n')
print(json.dumps({'complete':True,'path':str(path),'deltaLines':len(s.splitlines())-len(old.splitlines())}))
