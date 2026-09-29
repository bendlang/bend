from pathlib import Path
import shutil,json,hashlib,difflib
root=Path.cwd();base=root/'selfhost';out=base/'build/phase16/checker-source-03';out.mkdir();shutil.copytree(base/'build/phase16/checker-source-02/project',out/'project');project=out/'project'
def replace(s,a,b):assert s.count(a)==1,(a,s.count(a));return s.replace(a,b)
p=project/'src/diagnostic/trace.bend';s=p.read_text();s=replace(s,'  dg_kind_result(t, q, name, typ(kindq(e, q)), check(e, ctx, t, 0, typ(kindq(e, q))))','  +kind = typ(kindq(e, q))\n  dg_kind_result(t, q, name, kind, check(e, ctx, t, 0, kind))');p.write_text(s)
p=project/'src/check/kernel.bend';s=p.read_text();s=replace(s,'def check_adt_declaration(e, d):\n  check_adt_kind(e, d, dt(d), Nil{})','def check_adt_declaration(e, d):\n  kc(KChecked, String.eq(tg(tele_tip(cb(e), dt(d))), "Typ"), u => check_ctors(e, d, dc(d), dt(d)), u => check_adt_kind(e, d, dt(d), Nil{}))');p.write_text(s)
p=project/'src/check/specialize.bend';s=p.read_text();s=replace(s,'KSpecialized{+book: List<&2, KDef>, +error: String}','KSpecialized{+book: List<&2, KDef>, +error: KChecked}');s=replace(s,'+fresh: U32, +error: String, +templates:', '+fresh: U32, +error: KChecked, +templates:')
s=replace(s,'def specialized_error(\n  +r: KSpecialized,\n) -> String:\n  match r:\n    case KSpecialized{book, error}:\n      error','''def specialized_error(
  +r: KSpecialized,
) -> String:
  match r:
    case KSpecialized{book, error}:
      ce(error)

@unsafe
def specialized_diagnostic(+r: KSpecialized) -> DResult:
  match r:
    case KSpecialized{book, error}: DResult{ce(error), book, dg_report(error, "")}''')
s=replace(s,'def sp_error(\n  +st: KSpecState,\n) -> String:\n  match st:\n    case KSpecState{book, memo, serial, fresh, error, templates}:\n      error','''def sp_error(
  +st: KSpecState,
) -> String:
  ce(sp_checked(st))

@unsafe
def sp_checked(+st: KSpecState) -> KChecked:
  match st:
    case KSpecState{book, memo, serial, fresh, error, templates}: error''')
s=replace(s,'  KSpecState{sp_book(st), sp_memo(st), sp_serial(st), sp_fresh(st), kc(String, String.eq(sp_error(st), ""), u => err, u => sp_error(st)), sp_templates(st)}','''  sp_failed(st, bad(err))

@unsafe
def sp_failed(+st: KSpecState, +error: KChecked) -> KSpecState:
  kc(KSpecState, good(sp_checked(st)), u => KSpecState{sp_book(st), sp_memo(st), sp_serial(st), sp_fresh(st), error, sp_templates(st)}, u => st)

@unsafe
def sp_template_error(+st: KSpecState, +ctx: List<&2, KTerm>, +owner: String, +head: KTerm, +message: String, +expected: String) -> KSpecState:
  sp_failed(st, dg_trace(KEnv{sp_book(st), owner, ref(owner), 0, Nil{}, du(lookup(sp_book(st), owner))}, ctx, head, atom("Absent"), dg_bad_detail(message, dg_text(expected), head)))''')
s=s.replace('sp_error(st), sp_templates(st)', 'sp_checked(st), sp_templates(st)')
s=replace(s,'KSpecialized{index_remove(sp_book(st), "$kernel.max-id"), sp_error(st)}','KSpecialized{index_remove(sp_book(st), "$kernel.max-id"), sp_checked(st)}')
s=replace(s,'U32.add(bound, 1), "", sp_template_book(book)','U32.add(bound, 1), bad(""), sp_template_book(book)')
for name in ['sp_template','sp_template_args','sp_template_checked','sp_template_key','sp_instance']:
 start=s.index('law '+name+':');pos=s.index('  for +st: KSpecState\n',start)+len('  for +st: KSpecState\n');s=s[:pos]+'  for +head: KTerm\n'+('  for +ctx: List<&2, KTerm>\n' if name=='sp_instance' else '')+s[pos:]
 s=s.replace(name+'(st, d,',name+'(st, head, '+('ctx, ' if name=='sp_instance' else '')+'d,')
s=replace(s,'sp_fail(st, "template requires all closed comptime arguments")','sp_template_error(st, ctx, owner, head, "template requires all closed comptime arguments", "a template applied to closed ~ arguments (a def parameter is not comptime)")')
s=replace(s,'sp_fail(st, ce(checked))','sp_failed(st, dg_template_result(KEnv{sp_book(st), owner, ref(owner), 0, Nil{}, du(d)}, ctx, head, checked))')
s=replace(s,'sp_fail(st, "a comptime argument must stop growing")','sp_template_error(st, ctx, owner, head, "a comptime argument must stop growing", "a ~ argument that stops growing")')
s=replace(s,'sp_fail(st, "nondecreasing cross-instance template recursion")','sp_template_error(st, ctx, owner, head, "nondecreasing cross-instance template recursion", "a decreasing self-call (arguments are read left to right: each passed unchanged until one shrinks)")')
s=replace(s,'sp_fail(st, "template instantiation exceeds 64 levels")','sp_template_error(st, ctx, owner, head, "template instantiation exceeds 64 levels", "a template that stops instantiating itself (64 levels at most)")')
s=replace(s,'law sp_validate_done:\n  for +st: KSpecState\n  for +d: KDef\n  for +error: String','law sp_validate_done:\n  for +st: KSpecState\n  for +d: KDef\n  for +error: KChecked')
s=replace(s,'check_definition(sp_book(st), d)','check_definition_result(sp_book(st), d)')
s=replace(s,'def sp_validate_done(st, d, error):\n  kc(KSpecTerm, String.eq(error, ""),','def sp_validate_done(st, d, error):\n  kc(KSpecTerm, good(error),')
s=replace(s,'sp_fail(st, dn(d) ++ ": " ++ error)','sp_failed(st, KChecked{ct(error), cy(error), cs(error), dn(d) ++ ": " ++ ce(error)})')
p.write_text(s)
p=project/'tools/typed-driver.mjs';s=p.read_text();s=replace(s,"    exports.push('specialize_book','specialized_book','specialized_error');","    exports.push('specialize_book','specialized_book','specialized_error');\n    if(fs.readFileSync(path.join(project,'src/check/specialize.bend'),'utf8').includes('def specialized_diagnostic('))exports.push('specialized_diagnostic');")
start=s.index('          // New APIs return the original authoritative result.');end=s.index('\n        } catch(error)',start)
s=s[:start]+'''          rendered=renderDiagnostic(api,detailed,diagnostic,loadTrace,graph);'''+s[end:]
s=replace(s,"      if(error) return {status:'error',phase,diagnostic:'Error: '+error,exitCode:1,checked:true};", "      if(error) return {status:'error',phase,diagnostic:renderDiagnostic(api,api.specialized_diagnostic?.(specialized),error,loadTrace,graph),exitCode:1,checked:true};")
marker='async function inspectWithMemo('
helper='''// Both checker stages carry the original result into the same rejection renderer.
function renderDiagnostic(api,detailed,diagnostic,loadTrace,graph) {
  if(detailed?.error!==diagnostic)return 'Error: '+diagnostic;
  try {
    if(api.f_load_origins_for&&api.diagnostic_result_locate&&detailed.diagnostic.definition) {
      const provenance=loadTrace&&api.f_loaded_origins_for?
        api.f_loaded_origins_for(loadTrace,detailed.diagnostic.definition):
        api.f_load_origins_for(graph.main,graph.sources,detailed.diagnostic.definition);
      if(!provenance.result.error)detailed=api.diagnostic_result_locate(detailed,provenance.origins);
    }
    return api.diagnostic_render(detailed);
  } catch(error) {trace('diagnostic rendering unavailable: '+error.message);return 'Error: '+diagnostic;}
}

'''
assert s.count(marker)==1;s=s.replace(marker,helper+marker);p.write_text(s)
changes=[]
for name in ['src/check/kernel.bend','src/diagnostic/trace.bend','src/check/specialize.bend','tools/typed-driver.mjs']:
 before=(base/name).read_bytes();after=(project/name).read_bytes();changes.append({'file':name,'beforeSha256':hashlib.sha256(before).hexdigest(),'afterSha256':hashlib.sha256(after).hexdigest(),'physicalLineDelta':len(after.splitlines())-len(before.splitlines()),'byteDelta':len(after)-len(before)});(out/(name.replace('/','_')+'.patch')).write_text(''.join(difflib.unified_diff(before.decode().splitlines(True),after.decode().splitlines(True),fromfile=name,tofile=name)))
(out/'manifest.json').write_text(json.dumps({'kind':'phase16-specialization-transport-candidate','changes':changes,'toolSha256':hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),'plan':str(root/'design/phase16/checker-specialization.md')},indent=2)+'\n');(out/'config.json').write_text(json.dumps({'project':str(project),'upstream':str(base/'.bootstrap/upstream-phase8'),'profile':'equality','cpu':'1','jobs':1},indent=2)+'\n');print(out)
