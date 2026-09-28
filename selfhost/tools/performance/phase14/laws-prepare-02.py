import pathlib,shutil,json,hashlib
root=pathlib.Path.cwd();old=root/'selfhost/build/phase14/laws-candidate-01/project';out=root/'selfhost/build/phase14/laws-candidate-02';out.mkdir();project=out/'project'
for name in ['src','tools','tests/frontend/phase2-rules']:shutil.copytree(old/name,project/name)
(project/'dist').mkdir()
def change(file,old,new):
 p=project/file;s=p.read_text();assert s.count(old)==1,(file,old[:70],s.count(old));p.write_text(s.replace(old,new))
change('src/load/graph.bend','f_module_defs(f_graph_fills(book, List.reverse(&2, KDef, prior), imports), book, f_family_book(prior), ns, imports)','f_module_defs(book, book, f_family_book(prior), ns, imports)')
change('src/load/graph.bend','Con{KDef{dn(d), dk(d), da(d), dx(d), f_alias_term(dt(d), imports, scope), f_alias_term(dv(d), imports, scope), f_alias_defs(dc(d), imports, scope), db(d), du(d)}, f_alias_defs(rest, imports, scope)}','Con{f_graph_fill_alias(KDef{dn(d), dk(d), da(d), dx(d), f_alias_term(dt(d), imports, scope), f_alias_term(dv(d), imports, scope), f_alias_defs(dc(d), imports, scope), db(d), du(d)}, imports, scope), f_alias_defs(rest, imports, scope)}')
# Imported fills now sit in visible; exclude their canonical names from local qualification.
change('src/load/modules.bend','f_eq(name, dn(d)), u => True{}','f_eq(name, dn(d)) && Bool.not(f_eq(dk(d), "ImportFill")), u => True{}')
p=project/'src/load/graph.bend';s=p.read_text();beg=s.index('law f_graph_fills:');end=s.index('@unsafe\ndef f_graph_fill(+d:',beg)
s=s[:beg]+'''@unsafe
def f_graph_fill_alias(+d: KDef, +imports: List<&2,KTerm>, +scope: List<&2,KDef>) -> KDef:
  f_choose(KDef, f_eq(tg(dt(d)), "ImportLaw"), u => f_graph_fill(d, f_find(f_alias(dn(d), imports), List.reverse(&2, KDef, scope))), u => d)

'''+s[end:];s=s.replace('&& U32.is_ge(da(d), dx(old)),','&& U32.is_ge(da(d), dx(old)) && (Bool.not(f_eq(tg(dv(d)), "Foreign")) || U32.is_eq(dx(old), 0)),');p.write_text(s)
change('src/driver/report.bend','dr_bad_names(book_cached(book, norm_max_book(book)), dr_own_names(book, Nil{}))','dr_bad_names(book_cached(book_final_fast(book, Nil{}), norm_max_book(book)), dr_own_names(book, Nil{}))')
change('tools/typed-driver.mjs','api.driver_report(book,list([]))','api.driver_report(loaded.book,list([]))')
change('tools/typed-driver.mjs','array(api.driver_bad_names(book))','array(api.driver_bad_names(loaded.book))')
change('src/front/sugar.bend','f_choose(String, f_eq(tg(t), "Error"), u => nm(t), u => f_error_terms(ks(t)))','f_choose(String, f_eq(tg(t), "Error"), u => nm(t), u => f_choose(String, f_eq(tg(t), "ImportLaw"), u => "imported law fills require the canonical graph loader", u => f_error_terms(ks(t))))')
config={'project':str(project),'upstream':str(root/'selfhost/.bootstrap/upstream-phase8'),'profile':'equality','cpu':'2','jobs':1}
(out/'config.json').write_text(json.dumps(config,indent=2)+'\n')
(out/'plan.json').write_text(json.dumps({'kind':'phase14-imported-law-candidate','scope':'Fuse fills into existing alias walk; claim order from source events with latest definitions; legacy loader fails closed.','consumedTool':str(pathlib.Path(__file__).resolve()),'sha256':hashlib.sha256(pathlib.Path(__file__).read_bytes()).hexdigest()},indent=2)+'\n')
