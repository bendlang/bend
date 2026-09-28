import pathlib,shutil,json,hashlib,sys
root=pathlib.Path.cwd();out=root/'selfhost/build/phase14/laws-candidate-01';out.mkdir();project=out/'project'
for name in ['src','tools','tests/frontend/phase2-rules']:
 shutil.copytree(root/'selfhost'/name,project/name)
(project/'dist').mkdir()
def change(file,old,new):
 p=project/file;s=p.read_text();assert s.count(old)==1,(file,old[:70],s.count(old));p.write_text(s.replace(old,new))
change('src/front/declarations.bend','FParsed{dt(f_find(name, book)), ts}','FParsed{f_choose(KTerm, f_eq(dk(f_find(name, book)), "Missing") && Bool.not(f_eq(f_alias(name, imports), name)), u => kt("ImportLaw", name, 0, 0, ks(pars)), u => dt(f_find(name, book))), ts}')
change('src/front/declarations.bend','f_eq(dk(f_find(name, book)), "Missing"), u => f_tbind(pars, ty)','f_eq(dk(f_find(name, book)), "Missing") && Bool.not(f_eq(tg(ty), "ImportLaw")), u => f_tbind(pars, ty)')
change('src/load/graph.bend','f_module_defs(book, book, f_family_book(prior), ns, imports)','f_module_defs(f_graph_fills(book, List.reverse(&2, KDef, prior), imports), book, f_family_book(prior), ns, imports)')
change('src/load/graph.bend','Con{f_choose(KDef, String.is_empty(ns), u => f_elab_def(d, scope), u => f_qual_def(f_elab_def(d, scope), visible, ns, imports)), f_module_defs(rest, visible, scope, ns, imports)}','Con{f_choose(KDef, f_eq(dk(d), "ImportFill"), u => KDef{dn(d), "Def", da(d), dx(d), dt(d), f_qual_term(f_scope(dv(d), Nil{}, scope), visible, ns, imports), Nil{}, db(d), du(d)}, u => f_choose(KDef, String.is_empty(ns), u => f_elab_def(d, scope), u => f_qual_def(f_elab_def(d, scope), visible, ns, imports))), f_module_defs(rest, visible, scope, ns, imports)}')
p=project/'src/load/graph.bend'
p.write_text(p.read_text()+'''
# Imported fills retain their raw telescope until dependencies have loaded.
# The temporary kind protects the already-canonical law type and name from
# module qualification; f_module_def eliminates it before checker entry.
law f_graph_fills:
  for +book: List<&2,KDef>
  for +prior: List<&2,KDef>
  for +imports: List<&2,KTerm>
  List<&2,KDef>
law f_graph_fill_next:
  for +d: KDef
  for +rest: List<&2,KDef>
  for +prior: List<&2,KDef>
  for +imports: List<&2,KTerm>
  List<&2,KDef>

@unsafe
def f_graph_fills(book, prior, imports):
  match book:
    case Nil{}: Nil{}
    case Con{d, rest}:
      f_graph_fill_next(f_choose(KDef, f_eq(tg(dt(d)), "ImportLaw"), u => f_graph_fill(d, f_find(f_alias(dn(d), imports), prior)), u => d), rest, prior, imports)
@unsafe
def f_graph_fill_next(d, rest, prior, imports):
  Con{d, f_graph_fills(rest, Con{d, prior}, imports)}

@unsafe
def f_graph_fill(+d: KDef, +old: KDef) -> KDef:
  f_choose(KDef, f_eq(dk(old), "Def") && f_eq(tg(dv(old)), "Absent") && Bool.not(db(old)) && f_bare_params(ks(dt(d))) && U32.is_ge(da(d), dx(old)),
    u => KDef{dn(old), "ImportFill", da(d), dx(old), dt(old), f_choose(KTerm, f_eq(tg(dv(d)), "Body"), u => kt("Body", "", fc_start(ks(dt(d)), dt(old), kid(dv(d), 1), True{}), 0, ks(dv(d))), u => dv(d)), Nil{}, False{}, du(old) || du(d)},
    u => KDef{dn(d), "Def", da(d), dx(d), kt("Error", "an imported definition must uniquely fill a non-native law with plain parameter names", 0, 0, Nil{}), dv(d), dc(d), db(d), du(d)})
''')
config={'project':str(project),'upstream':str(root/'selfhost/.bootstrap/upstream-phase8'),'profile':'equality','cpu':'2','jobs':1}
(out/'config.json').write_text(json.dumps(config,indent=2)+'\n')
(out/'selection.json').write_text((root/'selfhost/build/phase14/laws-reproduction-01/selection.json').read_text())
(out/'plan.json').write_text(json.dumps({'kind':'phase14-imported-law-candidate','scope':'Deferred imported law fill after loaded dependencies; original local parser and body elaborator retained.','consumedTool':str(pathlib.Path(__file__).resolve()),'sha256':hashlib.sha256(pathlib.Path(__file__).read_bytes()).hexdigest()},indent=2)+'\n')
