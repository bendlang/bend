# Pure module graph loader. The host supplies file bytes as FSource values;
# dependency traversal, cycle checks, alias resolution and qualification are Bend.
type FSource is Data:
  FSource{+name: String, +path: String, +text: String}
  FParsedSource{+name: String, +path: String, +text: String, +parsed: FResult}
  FLocatedSource{+source: FSource, begin: U32, end: U32}

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
  kc(KTerm, core_literal(t), u => t, u =>
    k_rebuild(t, f_choose(String, f_eq(tg(t), "Ref") || f_eq(tg(t), "ADT") || f_eq(tg(t), "Ctr") || f_eq(tg(t), "Mat"), u => f_resolve_name(nm(t), book, ns, imports), u => nm(t)), ix(t), qt(t), f_qual_terms(ks(t), book, ns, imports), rm(t), kb(t), ke(t)))

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
    case FLocatedSource{source, begin, end}:
      f_source_name(source)

@unsafe
def f_source_text(source):
  match source:
    case FSource{name, path, text}:
      text
    case FParsedSource{name, path, text, parsed}:
      text
    case FLocatedSource{source, begin, end}:
      f_source_text(source)

@unsafe
def f_source_path(source):
  match source:
    case FSource{name, path, text}:
      path
    case FParsedSource{name, path, text, parsed}:
      path
    case FLocatedSource{source, begin, end}:
      f_source_path(source)

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
    case FLocatedSource{source, begin, end}:
      f_parse_source_located(source, begin)

# Location ownership is separate from raw/parsed source delivery.
@unsafe
def f_source_located(+source: FSource, +begin: U32, +end: U32) -> FSource:
  FLocatedSource{source, begin, end}

@unsafe
def f_source_begin(+source: FSource) -> U32:
  match source:
    case FSource{name, path, text}: 0
    case FParsedSource{name, path, text, parsed}: 0
    case FLocatedSource{source, begin, end}: begin

@unsafe
def f_source_end(+source: FSource) -> U32:
  match source:
    case FSource{name, path, text}: 0
    case FParsedSource{name, path, text, parsed}: 0
    case FLocatedSource{source, begin, end}: end

@unsafe
def f_parse_source_located(+source: FSource, +begin: U32) -> FResult:
  match source:
    case FSource{name, path, text}: f_parse_indexed(begin, text)
    case FParsedSource{name, path, text, parsed}: parsed
    case FLocatedSource{source, innerBegin, innerEnd}:
      FResult{Nil{}, "nested source location wrapper", Nil{}}

# Only the leading header is inspected before dependencies finish.
type FHeader is Data:
  FHeader{+imports: List<&2,KTerm>, +error: String, +body: String, line: U32, offset: U32}

type FCompletion is Data:
  FCompletion{+graph: FGraph, +parsed: FResult}

@unsafe
def compiler_load_abi() -> U32:
  1

@unsafe
def f_header_line(+source: String, +acc: String, +size: U32) -> FScanned:
  match source:
    case SNil{}: FScanned{String.reverse(acc), "", size}
    case SCon{c, rest}:
      f_choose(FScanned, Char.is_eq(c, '\n'), u => FScanned{String.reverse(SCon{c, acc}), rest, U32.add(size, 1)}, u => f_header_line(rest, SCon{c, acc}, U32.add(size, dg_units(c))))

@unsafe
def f_header_space(+source: String) -> String:
  f_choose(String, Bool.not(String.is_empty(source)) && f_ascii_space(f_head(source)), u => f_header_space(f_tail(source)), u => source)

@unsafe
def f_header_prefix(+line: String) -> Bool:
  +text = f_header_space(line)
  String.is_empty(text) || Char.is_eq(f_head(text), '#') || Char.is_eq(f_head(text), '\n') || (String.starts_with(text, "import") && (String.is_empty(f_drop_chars(text, 6)) || f_ascii_space(f_head(f_drop_chars(text, 6))) || Char.is_eq(f_head(f_drop_chars(text, 6)), '\n')))

@unsafe
def f_header_scan(+source: String, +full: String, +start: U32, +line: U32, +offset: U32, +prefix: String) -> FHeader:
  f_header_next(f_header_line(source, "", 0), source, full, start, line, offset, prefix)

@unsafe
def f_header_next(+scanned: FScanned, +source: String, +full: String, +start: U32, +line: U32, +offset: U32, +prefix: String) -> FHeader:
  match scanned:
    case FScanned{word, rest, size}:
      f_choose(FHeader, Bool.not(String.is_empty(source)) && f_header_prefix(word),
        u => f_header_scan(rest, full, start, U32.add(line, 1), U32.add(offset, size), prefix ++ word),
        u => f_header_result(fpe_finish_indexed(start, full, f_tops(f_lex_cursor(prefix, 1, 0, 0, Nil{}, start, start), Nil{}, Nil{}, False{}, f_parse_scope_empty())), source, line, offset))

@unsafe
def f_header_result(+parsed: FResult, +body: String, +line: U32, +offset: U32) -> FHeader:
  match parsed:
    case FResult{book, error, imports}: FHeader{imports, error, body, line, offset}

@unsafe
def f_source_header(+source: FSource) -> FHeader:
  match source:
    case FSource{name, path, text}: f_header_scan(text, text, 0, 1, 0, "")
    case FParsedSource{name, path, text, parsed}: f_header_supplied(parsed)
    case FLocatedSource{inner, begin, end}: f_source_header_at(inner, begin)

@unsafe
def f_source_header_at(+source: FSource, +start: U32) -> FHeader:
  match source:
    case FSource{name, path, text}: f_header_scan(text, text, start, 1, 0, "")
    case FParsedSource{name, path, text, parsed}: f_header_supplied(parsed)
    case FLocatedSource{inner, begin, end}: FHeader{Nil{}, "nested source interval", "", 1, 0}

@unsafe
def f_header_supplied(+parsed: FResult) -> FHeader:
  match parsed:
    case FResult{book, error, imports}: FHeader{imports, "", "", 1, 0}

@unsafe
def f_header_imports(+header: FHeader) -> List<&2,KTerm>:
  match header:
    case FHeader{imports, error, body, line, offset}: imports

@unsafe
def f_source_body(+source: FSource, +header: FHeader, +prior: List<&2,KDef>, +ns: String, +aliases: List<&2,KTerm>, +start: U32) -> FResult:
  match source:
    case FSource{name, path, text}: f_body_header(text, header, FParseScope{prior, index_build(List.reverse(&2,KDef,prior)), ns, aliases, True{}}, start)
    case FParsedSource{name, path, text, parsed}: parsed
    case FLocatedSource{inner, begin, end}: f_source_body(inner, header, prior, ns, aliases, begin)

@unsafe
def f_body_header(+source: String, +header: FHeader, +scope: FParseScope, +start: U32) -> FResult:
  match header:
    case FHeader{imports, error, body, line, offset}:
      f_choose(FResult, String.is_empty(error),
        u => fpe_finish_indexed(start, source, f_tops(f_lex_cursor(body, line, 0, 0, Nil{}, f_cursor_add(start, offset), f_cursor_add(start, offset)), Nil{}, List.reverse(&2,KTerm,imports), False{}, scope)),
        u => FResult{Nil{}, error, imports})

@unsafe
def f_complete_source(+source: FSource, +ns: String, +header: FHeader, +sources: List<&2,FSource>, +graph: FGraph, +root: String) -> FCompletion:
  match graph:
    case FGraph{book, error, done}:
      f_choose(FCompletion, String.is_empty(error),
        u => f_complete_aliases(source, ns, header, graph, f_graph_aliases(f_header_imports(header), source, sources, root), book, sources),
        u => FCompletion{graph, FResult{Nil{}, error, Nil{}}})

@unsafe
def f_complete_aliases(+source: FSource, +ns: String, +header: FHeader, +graph: FGraph, +aliases: List<&2,KTerm>, +prior: List<&2,KDef>, +sources: List<&2,FSource>) -> FCompletion:
  f_complete_parsed(source, ns, aliases, graph, f_source_body(source, header, prior, ns, aliases, 0), sources)

@unsafe
def f_complete_parsed(+source: FSource, +ns: String, +aliases: List<&2,KTerm>, +graph: FGraph, +parsed: FResult, +sources: List<&2,FSource>) -> FCompletion:
  match parsed:
    case FResult{book, error, imports}:
      FCompletion{f_graph_finish(source, ns, book, aliases, graph, sources, error), parsed}

@unsafe
def f_completion_graph(+completion: FCompletion) -> FGraph:
  match completion:
    case FCompletion{graph, parsed}: graph

# The host has already checked the immutable cache identity. Bind the supplied
# source again here; a seed cannot inject definitions for a different file.
@unsafe
def f_complete_seed(+source: FSource, +graph: FGraph, +path: String, +text: String, +book: List<&2,KDef>) -> FCompletion:
  match graph:
    case FGraph{prior, error, done}:
      f_choose(FCompletion, String.is_empty(error),
        u => f_choose(FCompletion, f_seed_matches(source, path, text),
          u => FCompletion{fs_inject(graph, FSeed{path, book, ""}), FResult{Nil{}, "", Nil{}}},
          u => FCompletion{f_graph_error(graph, "Base seed source mismatch"), FResult{Nil{}, "Base seed source mismatch", Nil{}}}),
        u => FCompletion{graph, FResult{Nil{}, error, Nil{}}})
