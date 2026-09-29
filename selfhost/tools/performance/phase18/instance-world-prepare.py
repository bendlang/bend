"""Frozen no-new-effects KWorld representation ablation; no live-source edits."""
from pathlib import Path
import difflib,hashlib,json,re,shutil
ROOT=Path(__file__).resolve().parents[4]
BASE=ROOT/'selfhost/build/phase17/find-worker-source-01/project'
OUT=ROOT/'selfhost/build/phase18/instance-world-source-01'
PLAN=ROOT/'design/phase18/instance-world-representation.md'
def members(root):
 return {str(p.relative_to(root)):{'sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'bytes':p.stat().st_size,'mode':p.stat().st_mode&0o777} for p in sorted(root.rglob('*')) if p.is_file()}
def change(s,old,new,n=1):
 assert s.count(old)==n,(old,s.count(old),n);return s.replace(old,new)
def function(s,name,fn):
 m=re.search(r'^def '+name+r'\b',s,re.M);assert m,name
 end=re.search(r'^(?:@unsafe|def |law |type )',s[m.end():],re.M)
 b=m.end()+end.start() if end else len(s)
 old=s[m.start():b];new=fn(old);assert old!=new,name
 return s[:m.start()]+new+s[b:]
def world_calls(s,name,world):
 def update(b):
  m=re.search(r'\)\s*(?:->[^:\n]+)?:\n',b);assert m,name
  return b[:m.end()]+re.sub(r'\b(ok|bad|dg_bad_detail|dg_bad_message|dg_quant_error|dg_adt_error)\(',lambda m:m[1]+'('+world+', ',b[m.end():])
 return function(s,name,update)
def add_law_arg(s,name,arg):
 m=re.search(r'^law '+name+r':\n',s,re.M);assert m,name
 return s[:m.end()]+arg+s[m.end():]
before=members(BASE);assert len(before)==214
OUT.mkdir();project=OUT/'project';shutil.copytree(BASE,project)
files={n:(project/n).read_text() for n in ['src/check/kernel.bend','src/check/specialize.bend','src/check/annotate.bend','src/diagnostic/trace.bend','src/diagnostic/produce.bend']}
s=files['src/check/kernel.bend']
s=change(s,'KChecked{+term: KTerm, +typ: KTerm, +uses: List<&2, KTerm>, +error: String}','KChecked{+term: KTerm, +typ: KTerm, +uses: List<&2, KTerm>, +error: String, +world: KWorld, +consumed: U32}')
s=change(s,'KEnv{+book: List<&2, KDef>, +name: String, +lhs: KTerm, +pending: U32, +quantities: List<&2, KTerm>, +unsafe: Bool}','KEnv{+world: KWorld, +name: String, +lhs: KTerm, +pending: U32, +quantities: List<&2, KTerm>, +unsafe: Bool, +depth: U32}')
s=change(s,'case KEnv{book, name, lhs, pending, quantities, unsafe}:','case KEnv{world, name, lhs, pending, quantities, unsafe, depth}:',6)
s=function(s,'cb',lambda b:change(b,'      book','      kw_book(world)'))
s=change(s,'case KChecked{term, typ, uses, error}:','case KChecked{term, typ, uses, error, world, consumed}:',4)
s=function(s,'ok',lambda b:change(change(b,'def ok(\n','def ok(\n  +world: KWorld,\n'),'KChecked{t, ty, us, ""}','KChecked{t, ty, us, "", world, 0}'))
s=function(s,'bad',lambda b:change(change(b,'def bad(\n','def bad(\n  +world: KWorld,\n'),'KChecked{atom("Error"), atom("Error"), Nil{}, msg}','KChecked{atom("Error"), atom("Error"), Nil{}, msg, world, 0}'))
s=function(s,'checked',lambda b:change(b,'ok(t, ty, cs(r))','KChecked{t, ty, cs(r), "", rw(r), rx(r)}'))
s=function(s,'both',lambda b:change(b,'ok(t, ty, uses_merge(cs(a), cs(b), join))','KChecked{t, ty, uses_merge(cs(a), cs(b), join), "", rw(b), rx(b)}'))
s=function(s,'lhs_step',lambda b:change(b,'KEnv{cb(e), cn(e), kapply(cl(e), x), U32.sub(cp(e), 1), cq(e), cu(e)}','KEnv{cw(e), cn(e), kapply(cl(e), x), U32.sub(cp(e), 1), cq(e), cu(e), cd(e)}'))
s=function(s,'mat_lhs',lambda b:change(change(b,'KEnv{cb(e),','KEnv{cw(e),'),', cq(e), cu(e)}',', cq(e), cu(e), cd(e)}'))
s=add_law_arg(s,'infer_var','  for +e: KEnv\n')
s=change(s,'infer_var(ctx, t, dem)','infer_var(e, ctx, t, dem)',2)
ordinary=['infer_node','infer_var','infer_ref','infer_app_type','infer_adt','tele_check','tele_check_head','check_node','check_lam','check_lam_q','check_ctr','check_rfl','check_let','check_mat','check_mat_type','check_mat_ctr','check_rwt_type','check_adt_kind_head','check_ctors','check_ctor_tel','check_ctor_head','infer_template','template_args','template_arg_head','tele_check_cached_head','tele_check_static','tele_check_legacy','tele_check_legacy_head']
for n in ordinary:s=world_calls(s,n,'cw(e)')
for n in ['check_fits','check_lam_done','check_let_done']:s=world_calls(s,n,'rw(r)')
s=world_calls(s,'check_rwt_goal','rw(motive)')
s=function(s,'check_ctors',lambda b:change(b,'KEnv{cb(e), dn(h), ref(dn(h)), 0, Nil{}, cu(e)}','KEnv{cw(e), dn(h), ref(dn(h)), 0, Nil{}, cu(e), cd(e)}'))
s=function(s,'check_definition_result',lambda b: 'def check_definition_result(book, d):\n  check_definition_world(kw_initial(book), d, 0)\n\n')
s=function(s,'check_definition_type',lambda b:change(change(b,'check_foreign(book, d)','check_foreign(cw(e), d, cd(e))'),'check_template_definition(book, d, dt(d), dv(d), ref(dn(d)), dx(d))','kw_restore_definition(cw(e), d, check_template_definition(cw(e), d, dt(d), dv(d), ref(dn(d)), dx(d), cd(e)))'))
s=change(s,'law check_foreign:\n  for +book: List<&2, KDef>\n  for +d: KDef\n','law check_foreign:\n  for +world: KWorld\n  for +d: KDef\n  for +depth: U32\n')
s=function(s,'check_foreign',lambda b:change(change(b,'def check_foreign(book, d):\n','def check_foreign(world, d, depth):\n  +book = kw_book(world)\n'),'KEnv{book, dn(d), ref(dn(d)), 0, Nil{}, du(d)}','KEnv{world, dn(d), ref(dn(d)), 0, Nil{}, du(d), depth}'))
s=world_calls(s,'check_foreign','world')
for name in ['check_template_definition','check_template_binder','check_template_open']:
 s=change(s,'law '+name+':\n  for +book: List<&2, KDef>','law '+name+':\n  for +world: KWorld')
 # append depth after existing parameters, before result type
 start=s.index('law '+name+':\n');end=s.index('\n  KChecked',start);s=s[:end]+'\n  for +depth: U32'+s[end:]
 s=function(s,name,lambda b:re.sub(r'def (\w+)\(book, (.*?)\):\n',r'def \1(world, \2, depth):\n  +book = kw_book(world)\n',b,count=1))
s=function(s,'check_template_definition',lambda b:change(change(b,'KEnv{book, dn(d), lhs, self_pending(d, body), tele_quantities(book, dt(d), da(d)), du(d)}','KEnv{world, dn(d), lhs, self_pending(d, body), tele_quantities(book, dt(d), da(d)), du(d), depth}'),'check_template_binder(book, d, wnf(book, ty), body, lhs, n)','check_template_binder(world, d, wnf(book, ty), body, lhs, n, depth)'))
s=function(s,'check_template_binder',lambda b:change(b,'check_template_open(book, d, ty, body, lhs, n, dn(d) ++ "~" ++ nm(ty))','check_template_open(world, d, ty, body, lhs, n, dn(d) ++ "~" ++ nm(ty), depth)'))
s=world_calls(s,'check_template_binder','world')
s=function(s,'check_template_open',lambda b:change(change(change(b,'check_template_definition(book_put(book, KDef{name, "Def", 0, 0, kid(ty, 0), atom("Absent"), Nil{}, True{}, False{}}),','check_template_definition(kw_with_book(world, book_put(book, KDef{name, "Def", 0, 0, kid(ty, 0), atom("Absent"), Nil{}, True{}, False{}})),'),'U32.sub(n, 1))','U32.sub(n, 1), depth)'),'KEnv{book, "", ref(dn(d)), 0, Nil{}, du(d)}','KEnv{world, "", ref(dn(d)), 0, Nil{}, du(d), depth}'))
s=world_calls(s,'check_template_open','world')
s+='''
# Stage1 world transport only: no deferred fresh bound is resolved here.
type KWorldFresh is Data:
  KFreshKnown{+next: U32}
  KFreshDeferred{}

type KWorld is Data:
  KWorld{+book: List<&2,KDef>, +memo: List<&2,KSpecMemo>, +fresh: KWorldFresh}

@unsafe
def kw_initial(+book: List<&2,KDef>) -> KWorld:
  KWorld{book, Nil{}, KFreshDeferred{}}

@unsafe
def kw_book(+world: KWorld) -> List<&2,KDef>:
  match world:
    case KWorld{book, memo, fresh}: book

@unsafe
def kw_memo(+world: KWorld) -> List<&2,KSpecMemo>:
  match world:
    case KWorld{book, memo, fresh}: memo

@unsafe
def kw_fresh(+world: KWorld) -> KWorldFresh:
  match world:
    case KWorld{book, memo, fresh}: fresh

@unsafe
def kw_with_book(+world: KWorld, +book: List<&2,KDef>) -> KWorld:
  KWorld{book, kw_memo(world), kw_fresh(world)}

@unsafe
def cw(+e: KEnv) -> KWorld:
  match e:
    case KEnv{world, name, lhs, pending, quantities, unsafe, depth}: world

@unsafe
def cd(+e: KEnv) -> U32:
  match e:
    case KEnv{world, name, lhs, pending, quantities, unsafe, depth}: depth

@unsafe
def rw(+r: KChecked) -> KWorld:
  match r:
    case KChecked{term, typ, uses, error, world, consumed}: world

@unsafe
def rx(+r: KChecked) -> U32:
  match r:
    case KChecked{term, typ, uses, error, world, consumed}: consumed

@unsafe
def kw_restore_definition(+world: KWorld, +d: KDef, +r: KChecked) -> KChecked:
  kc(KChecked, good(r) && U32.is_gt(dx(d), 0), u => KChecked{ct(r), cy(r), cs(r), ce(r), kw_with_book(rw(r), kw_book(world)), rx(r)}, u => r)

@unsafe
def check_definition_world(+world: KWorld, +d: KDef, +depth: U32) -> KChecked:
  +e = KEnv{world, dn(d), ref(dn(d)), 0, Nil{}, du(d), depth}
  check_definition_type(kw_book(world), d, e, check(e, Nil{}, dt(d), 0, typ(1)))
'''
files['src/check/kernel.bend']=s
s=files['src/diagnostic/trace.bend']
for name in ['dg_bad_detail','dg_bad_message']:
 s=add_law_arg(s,name,'  for +world: KWorld\n')
 s=function(s,name,lambda b:change(change(b,'def '+name+'(','def '+name+'(world, '),'Nil{}, message}','Nil{}, message, world, 0}'))
for name in ['dg_trace','dg_trace_detail','dg_kind_result']:
 s=function(s,name,lambda b:change(b,'cy(r), cs(r), ce(r)}','cy(r), cs(r), ce(r), rw(r), rx(r)}'))
s=world_calls(s,'dg_template_result','rw(r)')
files['src/diagnostic/trace.bend']=s
s=files['src/diagnostic/produce.bend']
for name in ['dg_quant_error','dg_adt_error']:
 s=add_law_arg(s,name,'  for +world: KWorld\n')
 s=function(s,name,lambda b:change(b,'def '+name+'(','def '+name+'(world, '))
 s=world_calls(s,name,'world')
s=world_calls(s,'dg_ctor_error','cw(e)')
files['src/diagnostic/produce.bend']=s
s=files['src/check/annotate.bend']
s=change(s,'KEnv{book, dn(d), ref(dn(d)), 0, Nil{}, du(d)}','KEnv{kw_initial(book), dn(d), ref(dn(d)), 0, Nil{}, du(d), 0}')
files['src/check/annotate.bend']=s
s=files['src/check/specialize.bend']
# All existing specializer/checker crossings retain the actual state.
s=world_calls(s,'sp_fail','sp_world(st)')
s=world_calls(s,'sp_template_error','sp_world(st)')
s=change(s,'KEnv{sp_book(st), owner, ref(owner), 0, Nil{}, du(lookup(sp_book(st), owner))}','KEnv{sp_world(st), owner, ref(owner), 0, Nil{}, du(lookup(sp_book(st), owner)), 0}')
s=change(s,'KEnv{sp_book(st), owner, ref(owner), 0, Nil{}, True{}}','KEnv{sp_world(st), owner, ref(owner), 0, Nil{}, True{}, 0}')
s=change(s,'KEnv{sp_book(st), owner, ref(owner), 0, Nil{}, du(d)}','KEnv{sp_world(st), owner, ref(owner), 0, Nil{}, du(d), depth}',2)
s=function(s,'sp_validate_done',lambda b:change(b,'dn(d) ++ ": " ++ ce(error)}','dn(d) ++ ": " ++ ce(error), rw(error), rx(error)}'))
for name in ['sp_mint_body','sp_validate']:
 m=re.search(r'^law '+name+r':\n',s,re.M);assert m,name
 end=s.index('\n  KSpecTerm',m.end());s=s[:end]+'\n  for +depth: U32'+s[end:]
 s=function(s,name,lambda b:re.sub(r'def (\w+)\((.*?)\):\n',r'def \1(\2, depth):\n',b,count=1))
s=function(s,'sp_mint_type',lambda b:change(b,'body, Nil{}, ty, name, depth))','body, Nil{}, ty, name, depth), depth)'))
s=function(s,'sp_mint_body',lambda b:change(b,'Nil{}, False{}, du(d)})','Nil{}, False{}, du(d)}, depth)'))
s=function(s,'sp_validate',lambda b:change(b,'check_definition_result(sp_book(st), d)','check_definition_world(sp_world(st), d, depth)'))
s=function(s,'sp_initial',lambda b:change(change(b,'  KSpecState{sp_stamp(check_declarations(book, Nil{}), bound),','  +declared = sp_stamp(check_declarations(book, Nil{}), bound)\n  KSpecState{declared,'),'bad("")','bad(KWorld{declared, Nil{}, KFreshKnown{U32.add(bound, 1)}}, "")'))
s+='''
@unsafe
def sp_world(+st: KSpecState) -> KWorld:
  KWorld{sp_book(st), sp_memo(st), KFreshKnown{sp_fresh(st)}}
'''
files['src/check/specialize.bend']=s
for rel,s in files.items():(project/rel).write_text(s)
after=members(project);changes=[n for n in before if before[n]!=after[n]];assert sorted(changes)==sorted(files)
patch=''.join(''.join(difflib.unified_diff((BASE/n).read_text().splitlines(True),(project/n).read_text().splitlines(True),fromfile='a/'+n,tofile='b/'+n)) for n in changes)
(OUT/'source.patch').write_text(patch)
def census(root):
 strings=[(root/n).read_text() for n in before if n.endswith('.bend')]
 return {'physicalLines':sum(len(s.splitlines()) for s in strings),'nonblankLines':sum(sum(bool(l.strip()) for l in s.splitlines()) for s in strings),'bytes':sum(len(s.encode()) for s in strings),'definitions':sum(len(re.findall(r'^def ',s,re.M)) for s in strings),'laws':sum(len(re.findall(r'^law ',s,re.M)) for s in strings),'types':sum(len(re.findall(r'^type ',s,re.M)) for s in strings)}
old,new=census(BASE),census(project)
manifest={'kind':'phase18-world-representation-source','complete':True,'parent':str(BASE),'project':str(project),'before':before,'after':after,'changes':changes,'oldSource':old,'newSource':new,'delta':{k:new[k]-old[k] for k in old},'inputs':[{'file':str(p),'sha256':hashlib.sha256(p.read_bytes()).hexdigest()} for p in [Path(__file__),PLAN]],'semanticInstantiation':False,'installed':False}
(OUT/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
(OUT/'workflow.json').write_text(json.dumps({'project':str(project),'upstream':str(ROOT/'selfhost/.bootstrap/upstream-phase8'),'profile':'equality','cpu':'1','jobs':1},indent=2)+'\n')
print(json.dumps({'changes':changes,'delta':manifest['delta']}))
