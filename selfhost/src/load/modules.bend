# Pure module graph loader. The host supplies file bytes as FSource values;
# dependency traversal, cycle checks, alias resolution and qualification are Bend.
type FSource is Data:
  FSource{+name: String, +path: String, +text: String}
  FParsedSource{+name: String, +path: String, +text: String, +parsed: FResult}

# The load trace is part of the loader API, also usable without diagnostics.
type FLoadTrace is Data:
  FLoadTrace{+result: FResult, +done: List<&2,KTerm>, +sources: List<&2,FSource>}

type FLoaded is Data:
  FLoaded{+book: List<&2, KDef>, +error: String, +seen: List<&2, String>}

law f_qual_result:
  for +r: FResult
  for +ns: String
  FResult

law f_alias:
  for +name: String
  for +imports: List<&2, KTerm>
  String

law f_qual_terms:
  for +ts: List<&2, KTerm>
  for +book: List<&2, KDef>
  for +ns: String
  for +imports: List<&2, KTerm>
  List<&2, KTerm>

law f_qual_def:
  for +d: KDef
  for +book: List<&2, KDef>
  for +ns: String
  for +imports: List<&2, KTerm>
  KDef

law f_source:
  for +name: String
  for +sources: List<&2, FSource>
  FSource

law f_source_name:
  for +source: FSource
  String

law f_source_text:
  for +source: FSource
  String

law f_source_path:
  for +source: FSource
  String

law f_loaded_result:
  for +r: FLoaded
  FResult

law f_load_module:
  for +name: String
  for +ns: String
  for +sources: List<&2, FSource>
  for +seen: List<&2, String>
  for +stack: List<&2, String>
  FLoaded

law f_load_source:
  for +name: String
  for +ns: String
  for +source: FSource
  for +sources: List<&2, FSource>
  for +seen: List<&2, String>
  for +stack: List<&2, String>
  FLoaded

law f_load_parsed:
  for +name: String
  for +r: FResult
  for +sources: List<&2, FSource>
  for +seen: List<&2, String>
  for +stack: List<&2, String>
  FLoaded

law f_load_imports:
  for +imports: List<&2, KTerm>
  for +sources: List<&2, FSource>
  for +seen: List<&2, String>
  for +stack: List<&2, String>
  for +book: List<&2, KDef>
  FLoaded

law f_load_import_next:
  for +imports: List<&2, KTerm>
  for +sources: List<&2, FSource>
  for +stack: List<&2, String>
  for +book: List<&2, KDef>
  for +r: FLoaded
  FLoaded

@unsafe
def f_parse_at(
  +source: String,
  +namespace: String,
) -> FResult:
  f_qual_result(f_elaborate(f_parse(source)), namespace)

@unsafe
def f_qual_result(r, ns):
  match r:
    case FResult{+book, err, +imports}:
      FResult{f_qual_optional(book, book, ns, imports), err, imports}

@unsafe
def f_qual_name(
  +name: String,
  +ns: String,
) -> String:
  f_choose(String, String.is_empty(ns), u => name, u => ns ++ "." ++ name)

@unsafe
def f_prefix(
  +s: String,
  +prefix: String,
) -> Bool:
  f_choose(Bool, String.is_empty(prefix), u => True{}, u => f_choose(Bool, String.is_empty(s), u => False{}, u => Char.is_eq(f_head(s), f_head(prefix)) && f_prefix(f_tail(s), f_tail(prefix))))

@unsafe
def f_drop_prefix(
  +s: String,
  +prefix: String,
) -> String:
  f_choose(String, String.is_empty(prefix), u => s, u => f_drop_prefix(f_tail(s), f_tail(prefix)))

@unsafe
def f_alias(name, imports):
  match imports:
    case Nil{}:
      name
    case Con{+im, rest}:
      f_choose(String, U32.is_gt(terms_len(ks(im)), 0) && f_prefix(name, nm(kid(im, 0)) ++ "."), u => nm(im) ++ "." ++ f_drop_prefix(name, nm(kid(im, 0)) ++ "."), u => f_alias(name, rest))

@unsafe
def f_declared(
  +name: String,
  +book: List<&2, KDef>,
) -> Bool:
  match book:
    case Nil{}:
      False{}
    case Con{+d, ds}:
      f_choose(Bool, f_eq(name, dn(d)) && Bool.not(f_eq(dk(d), "ImportFill")), u => True{}, u => f_choose(Bool, f_declared(name, dc(d)), u => True{}, u => f_declared(name, ds)))

@unsafe
def f_resolve_name(
  +name: String,
  +book: List<&2, KDef>,
  +ns: String,
  +imports: List<&2, KTerm>,
) -> String:
  f_choose(String, f_declared(name, book), u => f_qual_name(name, ns), u => f_alias(name, imports))

@unsafe
def f_qual_term(
  +t: KTerm,
  +book: List<&2, KDef>,
  +ns: String,
  +imports: List<&2, KTerm>,
) -> KTerm:
  KTerm{tg(t), f_choose(String, f_eq(tg(t), "Ref") || f_eq(tg(t), "ADT") || f_eq(tg(t), "Ctr") || f_eq(tg(t), "Mat"), u => f_resolve_name(nm(t), book, ns, imports), u => nm(t)), ix(t), qt(t), f_qual_terms(ks(t), book, ns, imports), rm(t)}

@unsafe
def f_qual_terms(ts, book, ns, imports):
  match ts:
    case Nil{}:
      Nil{}
    case Con{t, rest}:
      Con{f_qual_term(t, book, ns, imports), f_qual_terms(rest, book, ns, imports)}

@unsafe
def f_qual_defs(
  +ds: List<&2, KDef>,
  +book: List<&2, KDef>,
  +ns: String,
  +imports: List<&2, KTerm>,
) -> List<&2, KDef>:
  match ds:
    case Nil{}:
      Nil{}
    case Con{d, rest}:
      Con{f_qual_def(d, book, ns, imports), f_qual_defs(rest, book, ns, imports)}

@unsafe
def f_qual_def(d, book, ns, imports):
  match d:
    case KDef{name, kind, arity, templates, ty, value, ctors, native, unsafe}:
      KDef{f_qual_name(name, ns), kind, arity, templates, f_qual_term(ty, book, ns, imports), f_qual_term(value, book, ns, imports), f_qual_defs(ctors, book, ns, imports), native, unsafe}

@unsafe
def f_source(name, sources):
  match sources:
    case Nil{}:
      FSource{"", "", ""}
    case Con{+source, rest}:
      f_choose(FSource, f_eq(name, f_source_name(source)), u => source, u => f_source(name, rest))

@unsafe
def f_source_name(source):
  match source:
    case FSource{name, path, text}:
      name
    case FParsedSource{name, path, text, parsed}:
      name

@unsafe
def f_source_text(source):
  match source:
    case FSource{name, path, text}:
      text
    case FParsedSource{name, path, text, parsed}:
      text

@unsafe
def f_source_path(source):
  match source:
    case FSource{name, path, text}:
      path
    case FParsedSource{name, path, text, parsed}:
      path

@unsafe
def f_load(
  +main: String,
  +sources: List<&2, FSource>,
) -> FResult:
  f_loaded_result(f_load_module(main, "", sources, Nil{}, Nil{}))

@unsafe
def f_loaded_result(r):
  match r:
    case FLoaded{book, err, seen}:
      f_fresh_result(FResult{book, err, Nil{}})

@unsafe
def f_load_module(name, ns, sources, seen, stack):
  f_choose(FLoaded, has_name(stack, name), u => FLoaded{Nil{}, "cyclic import: " ++ name, seen}, u => f_choose(FLoaded, has_name(seen, name), u => FLoaded{Nil{}, "", seen}, u => f_load_source(name, ns, f_source(name, sources), sources, seen, stack)))

@unsafe
def f_load_source(name, ns, source, sources, seen, stack):
  f_choose(FLoaded, String.is_empty(f_source_name(source)), u => FLoaded{Nil{}, "module source not supplied: " ++ name, seen}, u => f_load_parsed(name, f_path_result(f_parse_at(f_source_text(source), ns), f_source_path(source), f_eq(name, "Base")), sources, seen, stack))

@unsafe
def f_load_parsed(name, r, sources, seen, stack):
  match r:
    case FResult{book, +err, imports}:
      f_choose(FLoaded, String.is_empty(err), u => f_load_imports(imports, sources, Con{name, seen}, Con{name, stack}, book), u => FLoaded{book, err, seen})

@unsafe
def f_load_imports(imports, sources, seen, stack, book):
  match imports:
    case Nil{}:
      FLoaded{book, "", seen}
    case Con{+im, rest}:
      f_load_import_next(rest, sources, stack, book, f_load_module(nm(im), f_choose(String, f_eq(nm(im), "Base"), u => "", u => nm(im)), sources, seen, stack))

@unsafe
def f_load_import_next(imports, sources, stack, book, r):
  match r:
    case FLoaded{defs, +err, seen}:
      f_choose(FLoaded, String.is_empty(err), u => f_load_imports(imports, sources, seen, stack, norm_defs_join(defs, book)), u => FLoaded{book, err, seen})


law f_qual_optional:
  for +defs: List<&2, KDef>
  for +book: List<&2, KDef>
  for +ns: String
  for +imports: List<&2, KTerm>
  List<&2, KDef>

@unsafe
def f_qual_optional(defs, book, ns, imports):
  f_choose(List<&2, KDef>, String.is_empty(ns), u => defs, u => f_qual_defs(defs, book, ns, imports))

# Invocation-local parse handoff. The driver supplies the unqualified result of
# this compiler's parser; graph elaboration and validation still run normally.
law f_parse_source:
  for +source: FSource
  FResult

@unsafe
def f_source_parsed(
  +name: String,
  +path: String,
  +text: String,
  +parsed: FResult,
) -> FSource:
  FParsedSource{name, path, text, parsed}

@unsafe
def f_parse_source(source):
  match source:
    case FSource{name, path, text}:
      f_parse(text)
    case FParsedSource{name, path, text, parsed}:
      parsed
