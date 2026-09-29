# Canonical file identity is separate from each importing module's aliases.
# The host supplies lexical/canonical paths and guards active IO reentry.
# Supplied-source graph validation, namespace conflicts and cycles stay here.
type FGraph is Data:
  FGraph{+book: List<&2, KDef>, +error: String, +done: List<&2, KTerm>}

law f_path_parts:
  for +s: String
  for +part: String
  for +parts: List<&2,String>
  for +abs: Bool
  String

law f_path_push:
  for +part: String
  for +parts: List<&2,String>
  List<&2,String>

law f_path_parent:
  for +parts: List<&2,String>
  List<&2,String>

law f_path_join_parts:
  for +parts: List<&2,String>
  for +acc: String
  String

# Freshness is checked only after all existing graph/parser/elaborator errors.
# The index stores latest prior events; constructors have a separate namespace.
law f_graph_fresh_result:
  for +r: FResult
  FResult

law f_graph_fresh_names:
  for +todo: List<&2,KDef>
  for +done: KDef
  String

law f_graph_fresh_hashed:
  for +rest: List<&2,KDef>
  for +done: KDef
  for +d: KDef
  for +hash: U32
  String

law f_graph_load:
  for +path: String
  for +ns: String
  for +sources: List<&2,FSource>
  for +g: FGraph
  for +stack: List<&2,String>
  FGraph

law f_graph_error:
  for +g: FGraph
  for +err: String
  FGraph

law f_graph_aliases:
  for +imports: List<&2, KTerm>
  for +source: FSource
  for +sources: List<&2,FSource>
  for +root: String
  List<&2, KTerm>

law f_alias_terms:
  for +ts: List<&2, KTerm>
  for +imports: List<&2, KTerm>
  for +scope: List<&2,KDef>
  List<&2, KTerm>

law f_graph_finish:
  for +s: FSource
  for +ns: String
  for +book: List<&2,KDef>
  for +imports: List<&2, KTerm>
  for +g: FGraph
  FGraph

law f_graph_finish_alias:
  for +s: FSource
  for +ns: String
  for +book: List<&2,KDef>
  for +imports: List<&2, KTerm>
  for +prior: List<&2,KDef>
  for +err: String
  for +done: List<&2, KTerm>
  FGraph

@unsafe
def f_path_normal(
  +s: String,
) -> String:
  f_path_parts(s, "", Nil{}, Char.is_eq(f_head(s), '/'))

@unsafe
def f_path_parts(s, part, parts, abs):
  f_choose(String, String.is_empty(s), u => f_path_join_parts(List.reverse(&2, String, f_path_push(part, parts)), f_choose(String, abs, u => "/", u => "")), u => f_choose(String, Char.is_eq(f_head(s), '/'), u => f_path_parts(f_tail(s), "", f_path_push(part, parts), abs), u => f_path_parts(f_tail(s), part ++ SCon{f_head(s), ""}, parts, abs)))

@unsafe
def f_path_push(part, parts):
  f_choose(List<&2,String>, String.is_empty(part) || f_eq(part, "."), u => parts, u => f_choose(List<&2,String>, f_eq(part, ".."), u => f_path_parent(parts), u => Con{part, parts}))

@unsafe
def f_path_parent(parts):
  match parts:
    case Nil{}:
      [".."]
    case Con{+p, rest}:
      f_choose(List<&2,String>, f_eq(p, ".."), u => Con{"..", Con{p, rest}}, u => rest)

@unsafe
def f_path_join_parts(parts, acc):
  match parts:
    case Nil{}:
      acc
    case Con{part, rest}:
      f_path_join_parts(rest, acc ++ f_choose(String, String.is_empty(acc) || f_eq(acc, "/"), u => "", u => "/") ++ part)

@unsafe
def f_drop_chars(
  +s: String,
  +n: U32,
) -> String:
  f_choose(String, U32.is_eq(n, 0), u => s, u => f_drop_chars(f_tail(s), U32.sub(n, 1)))

@unsafe
def f_strip_bend(
  +s: String,
) -> String:
  String.reverse(f_drop_chars(String.reverse(s), 5))

@unsafe
def f_graph_source(
  +path: String,
  +sources: List<&2,FSource>,
) -> FSource:
  match sources:
    case Nil{}:
      FSource{"", "", ""}
    case Con{+s, rest}:
      f_choose(FSource, f_eq(path, f_source_name(s)) || f_eq(path, f_source_path(s)), u => s, u => f_graph_source(path, rest))

@unsafe
def f_load_graph(
  +main: String,
  +sources: List<&2,FSource>,
) -> FResult:
  f_graph_result_at(f_graph_load(main, "", sources, FGraph{Nil{}, "", Nil{}}, Nil{}), sources)

@unsafe
def f_graph_result(
  +g: FGraph,
) -> FResult:
  match g:
    case FGraph{book, err, done}:
      f_fresh_result(f_graph_fresh_result(f_validate_result(FResult{book, err, Nil{}})))

@unsafe
def f_graph_load(path, ns, sources, g, stack):
  # fs_source rejects empty source paths before this disabled seed can match.
  fs_load(path, ns, sources, g, stack, FSeed{"", Nil{}, f_path_dir(f_source_path(f_graph_source(path, sources)))})

@unsafe
def f_graph_error(g, err):
  match g:
    case FGraph{book, old, done}:
      FGraph{book, err, done}

@unsafe
def f_import_pathname(
  +im: KTerm,
  +s: FSource,
  +sources: List<&2,FSource>,
) -> String:
  f_choose(String, f_eq(nm(im), "Base"), u => f_source_path(f_source("Base", sources)), u => f_path_normal(f_path_join(f_path_dir(f_source_path(s)), nm(im))))

@unsafe
def f_graph_aliases(imports, source, sources, root):
  match imports:
    case Nil{}:
      Nil{}
    case Con{+im, rest}:
      Con{kt("Import", f_import_namespace_at(im, source, sources, root), 0, 0, ks(im)), f_graph_aliases(rest, source, sources, root)}

# Alias ambiguity uses the loaded declaration scope before rewriting names.
@unsafe
def f_alias_term(+t: KTerm, +imports: List<&2,KTerm>, +scope: List<&2,KDef>) -> KTerm:
  f_alias_named(t, imports, scope, f_choose(String, f_eq(tg(t), "Ref") || f_eq(tg(t), "ADT") || f_eq(tg(t), "Ctr") || f_eq(tg(t), "Mat"), u => f_alias(nm(t), imports), u => nm(t)))

@unsafe
def f_alias_named(+t: KTerm, +imports: List<&2,KTerm>, +scope: List<&2,KDef>, +name: String) -> KTerm:
  f_choose(KTerm, f_choose(Bool, Bool.not(String.eq(name, nm(t))), u => f_declared(name, scope) && f_declared(nm(t), scope), u => False{}),
    u => kt("Error", "expected an unambiguous name (an import alias shadows " ++ nm(t) ++ ")", 0, 0, Nil{}),
    u => KTerm{tg(t), name, ix(t), qt(t), f_alias_terms(ks(t), imports, scope), rm(t)})

@unsafe
def f_alias_terms(ts, imports, scope):
  match ts:
    case Nil{}: Nil{}
    case Con{t, rest}: Con{f_alias_term(t, imports, scope), f_alias_terms(rest, imports, scope)}

@unsafe
def f_alias_defs(+ds: List<&2,KDef>, +imports: List<&2,KTerm>, +scope: List<&2,KDef>) -> List<&2,KDef>:
  match ds:
    case Nil{}: Nil{}
    case Con{+d, rest}:
      Con{f_graph_fill_alias(KDef{dn(d), dk(d), da(d), dx(d), f_alias_term(dt(d), imports, scope), f_alias_term(dv(d), imports, scope), f_alias_defs(dc(d), imports, scope), db(d), du(d)}, imports, scope), f_alias_defs(rest, imports, scope)}

@unsafe
def f_graph_finish(s, ns, book, imports, g):
  match g:
    case FGraph{prior, +err, done}:
      # Reuse the ordinary freshness rule before module qualification can hide
      # a collision with Base or another declaration in the root namespace.
      f_graph_finish_alias(s, ns, f_alias_defs(book, imports, prior), imports, prior, f_choose(String, String.is_empty(err), u => f_graph_fresh_names(book, index_build(List.reverse(&2,KDef,prior))), u => err), done)

@unsafe
def f_graph_finish_alias(s, ns, book, imports, prior, err, done):
  FGraph{norm_defs_join(prior, f_path_defs(f_module_defs(book, book, f_family_book(prior), ns, imports), f_path_dir(f_source_path(s)), f_eq(f_source_name(s), "Base"))), err, Con{kt("Loaded", f_source_path(s), f_graph_count_defs(book, 0), 0, [ref(ns)]), done}}


law f_module_defs:
  for +todo: List<&2, KDef>
  for +visible: List<&2, KDef>
  for +scope: List<&2, KDef>
  for +ns: String
  for +imports: List<&2, KTerm>
  List<&2, KDef>

law f_module_def:
  for +d: KDef
  for +rest: List<&2, KDef>
  for +visible: List<&2, KDef>
  for +scope: List<&2, KDef>
  for +ns: String
  for +imports: List<&2, KTerm>
  List<&2, KDef>

@unsafe
def f_module_defs(todo, visible, scope, ns, imports):
  match todo:
    case Nil{}:
      Nil{}
    case Con{+d, rest}:
      # Qualification sees the whole module. Parser sugar sees only prior
      # families/templates; checker declaration visibility is a separate rule.
      f_module_def(d, rest, visible, f_choose(List<&2,KDef>, f_eq(dk(d), "ADT") || U32.is_gt(dx(d), 0), u => Con{d, scope}, u => scope), ns, imports)

@unsafe
def f_module_def(d, rest, visible, scope, ns, imports):
  Con{f_choose(KDef, f_eq(dk(d), "ImportFill"), u => KDef{dn(d), "Def", da(d), dx(d), dt(d), f_qual_term(f_scope(dv(d), Nil{}, scope), visible, ns, imports), Nil{}, db(d), du(d)}, u => f_choose(KDef, String.is_empty(ns), u => f_elab_def(d, scope), u => f_qual_def(f_elab_def(d, scope), visible, ns, imports))), f_module_defs(rest, visible, scope, ns, imports)}

# Reporting uses the main module's declaration events, excluding dependencies.
# Upstream appends to book.order only for def/type/law declarations; constructors
# remain nested and lowering introduces terms rather than declaration events.
# Thus this source selection exactly recovers order.slice(n0), without rerunning
# imported modules or changing FResult's stable ABI. Call after a successful load.
law f_main_result_names:
  for +r: FResult
  List<&2,String>

law f_main_order:
  for +book: List<&2,KDef>
  for +seen: List<&2,String>
  List<&2,String>

@unsafe
def f_main_names(
  +main: String,
  +sources: List<&2,FSource>,
) -> List<&2,String>:
  f_main_result_names(f_parse_source(f_graph_source(main, sources)))

@unsafe
def f_main_result_names(r):
  match r:
    case FResult{book, error, imports}:
      f_choose(List<&2,String>, String.is_empty(error), u => f_main_order(book, Nil{}), u => Nil{})

@unsafe
def f_main_order(book, seen):
  match book:
    case Nil{}:
      Nil{}
    case Con{+d, rest}:
      f_choose(List<&2,String>, has_name(seen, dn(d)), u => f_main_order(rest, seen), u => Con{dn(d), f_main_order(rest, Con{dn(d), seen})})

# Request-local trace of the exact graph that produced the freshened core.
# Loaded.id records declaration-event count, including separate law/fill events.

law f_graph_trace:
  for +graph: FGraph
  for +sources: List<&2,FSource>
  FLoadTrace
law f_graph_count_defs:
  for +book: List<&2,KDef>
  for +count: U32
  U32

@unsafe
def f_load_graph_trace(
  +main: String,
  +sources: List<&2,FSource>,
) -> FLoadTrace:
  f_graph_trace(f_graph_load(main, "", sources, FGraph{Nil{}, "", Nil{}}, Nil{}), sources)
@unsafe
def f_graph_trace(graph, sources):
  match graph:
    case FGraph{book, error, done}:
      FLoadTrace{f_graph_result_at(graph, sources), done, sources}
@unsafe
def f_graph_count_defs(book, count):
  match book:
    case Nil{}: count
    case Con{head, tail}: f_graph_count_defs(tail, U32.add(count, 1))

@unsafe
def f_graph_fresh_result(r):
  match r:
    case FResult{+book, +err, +imports}:
      f_choose(FResult, String.is_empty(err), u => FResult{book, f_graph_fresh_names(book, missing()), imports}, u => FResult{book, err, imports})

@unsafe
def f_graph_fresh_names(todo, done):
  match todo:
    case Nil{}:
      ""
    case Con{+d, rest}:
      f_graph_fresh_hashed(rest, done, d, index_hash(dn(d), 2166136261))

@unsafe
def f_graph_fresh_name(
  +rest: List<&2,KDef>,
  +done: KDef,
  +d: KDef,
  +hash: U32,
  +old: KDef,
) -> String:
  f_choose(String, f_eq(dk(old), "Absent") || (f_eq(dk(old), "Def") && f_eq(dk(d), "Def") && f_eq(tg(dv(old)), "Absent") && Bool.not(f_eq(tg(dv(d)), "Absent")) && (Bool.not(db(old)) || db(d))), u => f_graph_fresh_names(rest, index_set(done, d, hash, 32)), u => "expected a fresh name (duplicate declaration: " ++ dn(d) ++ ")")

@unsafe
def f_graph_fresh_hashed(rest, done, d, hash):
  f_graph_fresh_name(rest, done, d, hash, index_find(done, dn(d), hash, 32))

# Refine only the error already selected by graph validation. Success is O(1).
law f_graph_result_at:
  for +graph: FGraph
  for +sources: List<&2,FSource>
  FResult
law fpe_graph_result:
  for +graph: FGraph
  for +sources: List<&2,FSource>
  for +result: FResult
  FResult
law fpe_rejected:
  for +result: FResult
  for +book: List<&2,KDef>
  for +done: List<&2,KTerm>
  for +sources: List<&2,FSource>
  FResult
law fpe_term:
  for +t: KTerm
  KTerm

law fpe_defs:
  for +ds: List<&2,KDef>
  KTerm

law fpe_terms:
  for +ts: List<&2,KTerm>
  KTerm
law fpe_terms_next:
  for +error: KTerm
  for +rest: List<&2,KTerm>
  KTerm
law fpe_defs_next:
  for +error: KTerm
  for +rest: List<&2,KDef>
  KTerm
law fpe_find:
  for +ds: List<&2,KDef>
  for +index: U32
  KTerm
law fpe_find_next:
  for +error: KTerm
  for +rest: List<&2,KDef>
  for +index: U32
  KTerm
law fpe_selected:
  for +legacy: String
  for +owner: KTerm
  for +done: List<&2,KTerm>
  for +sources: List<&2,FSource>
  String
law fpe_owner_path:
  for +done: List<&2,KTerm>
  for +index: U32
  String
law fpe_unique_source:
  for +path: String
  for +sources: List<&2,FSource>
  for +found: KTerm
  KTerm
law fpe_source_render:
  for +legacy: String
  for +error: KTerm
  for +source: KTerm
  String

@unsafe
def f_graph_result_at(graph, sources):
  fpe_graph_result(graph, sources, f_graph_result(graph))
@unsafe
def fpe_graph_result(graph, sources, result):
  match graph:
    case FGraph{book, error, done}:
      f_choose(FResult, String.is_empty(error), u => fpe_rejected(result, book, done, sources), u => result)
@unsafe
def fpe_rejected(result, book, done, sources):
  match result:
    case FResult{out, +error, imports}:
      FResult{out, f_choose(String, String.is_empty(error), u => error, u => fpe_selected(error, fpe_find(book, 0), done, sources)), imports}

# Exactly the existing f_error_* traversal order, including empty-name Error skip.
@unsafe
def fpe_term(t):
  f_choose(KTerm, f_eq(tg(t), "Error"), u => f_choose(KTerm, String.is_empty(nm(t)), u => atom("Absent"), u => t), u => f_choose(KTerm, f_eq(tg(t), "ImportLaw"), u => kt("Error", "imported law fills require the canonical graph loader", 0, 0, Nil{}), u => fpe_terms(ks(t))))
@unsafe
def fpe_terms(ts):
  match ts:
    case Nil{}: atom("Absent")
    case Con{head, tail}: fpe_terms_next(fpe_term(head), tail)
@unsafe
def fpe_terms_next(error, rest):
  f_choose(KTerm, f_eq(tg(error), "Absent"), u => fpe_terms(rest), u => error)
@unsafe
def fpe_def(
  +d: KDef,
) -> KTerm:
  fpe_defs_next(fpe_terms([dt(d), dv(d)]), dc(d))
@unsafe
def fpe_defs(ds):
  match ds:
    case Nil{}: atom("Absent")
    case Con{head, tail}: fpe_defs_next(fpe_def(head), tail)
@unsafe
def fpe_defs_next(error, rest):
  f_choose(KTerm, f_eq(tg(error), "Absent"), u => fpe_defs(rest), u => error)
@unsafe
def fpe_find(ds, index):
  match ds:
    case Nil{}: atom("Absent")
    case Con{head, tail}: fpe_find_next(fpe_def(head), tail, index)
@unsafe
def fpe_find_next(error, rest, index):
  f_choose(KTerm, f_eq(tg(error), "Absent"), u => fpe_find(rest, U32.add(index, 1)), u => kt("ParseOwner", "", index, 0, [error]))
@unsafe
def fpe_selected(legacy, owner, done, sources):
  f_choose(String, f_eq(tg(owner), "ParseOwner") && String.eq(nm(kid(owner, 0)), legacy), u => fpe_source_render(legacy, kid(owner, 0), fpe_unique_source(fpe_owner_path(List.reverse(&2, KTerm, done), ix(owner)), sources, atom("Absent"))), u => legacy)
@unsafe
def fpe_owner_path(done, index):
  match done:
    case Nil{}: ""
    case Con{head, tail}:
      f_choose(String, U32.is_lt(index, ix(head)), u => nm(head), u => fpe_owner_path(tail, U32.sub(index, ix(head))))
@unsafe
def fpe_unique_source(path, sources, found):
  match sources:
    case Nil{}: found
    case Con{head, tail}:
      f_choose(KTerm, String.eq(path, f_source_path(head)), u => f_choose(KTerm, f_eq(tg(found), "Absent"), u => fpe_unique_source(path, tail, kt("ParseSource", f_source_text(head), 0, 0, Nil{})), u => atom("Ambiguous")), u => fpe_unique_source(path, tail, found))
@unsafe
def fpe_source_render(legacy, error, source):
  f_choose(String, f_eq(tg(source), "ParseSource"), u => fpe_render(nm(source), error), u => legacy)

# Canonical module namespaces are relative to the entry's real directory.
# Reaching a file through another spelling therefore cannot create another name.
@unsafe
def f_relative_parts(+root: List<&2,String>, +file: List<&2,String>) -> String:
  match root file:
    case Con{r, rs} Con{f, fs}:
      f_choose(String, String.eq(r, f), u => f_relative_parts(rs, fs), u => f_relative_parents(root) ++ f_path_join_parts(file, ""))
    case _ _:
      f_relative_parents(root) ++ f_path_join_parts(file, "")

@unsafe
def f_relative_parents(+root: List<&2,String>) -> String:
  match root:
    case Nil{}: ""
    case Con{part, rest}: "../" ++ f_relative_parents(rest)

@unsafe
def f_import_namespace_at(+im: KTerm, +source: FSource, +sources: List<&2,FSource>, +root: String) -> String:
  f_choose(String, f_eq(nm(im), "Base"), u => "", u => f_strip_bend(f_relative_parts(f_path_segments(f_path_normal(root)), f_path_segments(f_source_path(f_graph_source(f_import_pathname(im, source, sources), sources))))))

@unsafe
def f_path_segments(+path: String) -> List<&2,String>:
  f_path_nonempty(String.split(path, '/'))

@unsafe
def f_path_nonempty(parts: List<&2,String>) -> List<&2,String>:
  match parts:
    case Nil{}: Nil{}
    case Con{+part, +rest}:
      f_choose(List<&2,String>, String.is_empty(part), u => f_path_nonempty(rest), u => Con{part, f_path_nonempty(rest)})

# Imported fills retain their raw telescope until dependencies have loaded.
# The temporary kind protects the already-canonical law type and name from
# module qualification; f_module_def eliminates it before checker entry.
@unsafe
def f_graph_fill_alias(+d: KDef, +imports: List<&2,KTerm>, +scope: List<&2,KDef>) -> KDef:
  f_choose(KDef, f_eq(tg(dt(d)), "ImportLaw"), u => f_graph_fill(d, f_find(f_alias(dn(d), imports), List.reverse(&2, KDef, scope))), u => d)

@unsafe
def f_graph_fill(+d: KDef, +old: KDef) -> KDef:
  f_choose(KDef, f_eq(dk(old), "Def") && f_eq(tg(dv(old)), "Absent") && Bool.not(db(old)) && f_bare_params(ks(dt(d))) && U32.is_ge(da(d), dx(old)) && (Bool.not(f_eq(tg(dv(d)), "Foreign")) || U32.is_eq(dx(old), 0)),
    u => KDef{dn(old), "ImportFill", da(d), dx(old), dt(old), f_choose(KTerm, f_eq(tg(dv(d)), "Body"), u => kt("Body", "", fc_start(ks(dt(d)), dt(old), kid(dv(d), 1), True{}), 0, ks(dv(d))), u => dv(d)), Nil{}, False{}, du(old) || du(d)},
    u => KDef{dn(d), "Def", da(d), dx(d), kt("Error", "an imported definition must uniquely fill a non-native law with plain parameter names", 0, 0, Nil{}), dv(d), dc(d), db(d), du(d)})
