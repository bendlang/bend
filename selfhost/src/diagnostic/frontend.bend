# Parser-owned ranges are resolved through immutable source intervals. An
# unlocated legacy trace is explicitly replayed; no term/text matching remains.
type FProvenance is Data:
  FProvenance{+result: FResult, +origins: List<&2,DOrigin>}

type FPSourceSet is Data:
  FPSourceSet{+sources: List<&2,FSource>, +error: String}

law fp_units:
  for +text: String
  for +count: U32
  U32
law fp_source_validate:
  for +source: FSource
  for +seen: List<&2,FSource>
  String
law fp_source_pairs:
  for +source: FSource
  for +seen: List<&2,FSource>
  String
law fp_source_inputs:
  for +sources: List<&2,FSource>
  for +seen: List<&2,FSource>
  String
law fp_source_limit:
  for +sources: List<&2,FSource>
  for +limit: U32
  U32
law fp_source_prior:
  for +path: String
  for +sources: List<&2,FSource>
  FSource
law fp_index_sources:
  for +sources: List<&2,FSource>
  for +seen: List<&2,FSource>
  for +next: U32
  FPSourceSet
law fp_index_one:
  for +source: FSource
  for +rest: List<&2,FSource>
  for +seen: List<&2,FSource>
  for +next: U32
  for +prior: FSource
  FPSourceSet
law fp_index_fresh:
  for +source: FSource
  for +rest: List<&2,FSource>
  for +seen: List<&2,FSource>
  for +next: U32
  for +size: U32
  FPSourceSet
law fp_origins:
  for +sources: List<&2,FSource>
  List<&2,DOrigin>
law fp_located:
  for +sources: List<&2,FSource>
  Bool
law fp_load_indexed:
  for +main: String
  for +inputs: FPSourceSet
  FProvenance
law fp_trace_ready:
  for +trace: FLoadTrace
  FProvenance

@unsafe
def fp_units(text, count):
  match text:
    case SNil{}: count
    case SCon{head, rest}: fp_units(rest, U32.add(count, dg_units(head)))

@unsafe
def fp_source_validate(source, seen):
  match source:
    case FSource{name, path, text}: fp_source_pairs(source, seen)
    case FCompletedSource{name, path, text, parsed}: fp_source_pairs(source, seen)
    case FLocatedSource{inner, begin, end}:
      match inner:
        case FLocatedSource{nested, a, b}: "nested source location wrapper"
        case FSource{name, path, text}:
          f_choose(String, U32.is_gt(begin, 0) && U32.is_gt(end, begin) && U32.is_eq(U32.sub(end, begin), U32.add(fp_units(text, 0), 1)), u => fp_source_pairs(source, seen), u => "invalid source interval")
        case FCompletedSource{name, path, text, parsed}:
          f_choose(String, U32.is_gt(begin, 0) && U32.is_gt(end, begin) && U32.is_eq(U32.sub(end, begin), U32.add(fp_units(text, 0), 1)), u => fp_source_pairs(source, seen), u => "invalid source interval")

@unsafe
def fp_source_pairs(source, seen):
  match seen:
    case Nil{}: ""
    case Con{old, rest}:
      f_choose(String, String.eq(f_source_path(source), f_source_path(old)),
        u => f_choose(String, f_seed_text_equal(f_source_text(source), f_source_text(old)) && U32.is_eq(f_source_begin(source), f_source_begin(old)) && U32.is_eq(f_source_end(source), f_source_end(old)), u => fp_source_pairs(source, rest), u => "source alias ownership changed"),
        u => f_choose(String, U32.is_gt(f_source_begin(source), 0) && U32.is_gt(f_source_begin(old), 0) && U32.is_lt(f_source_begin(source), f_source_end(old)) && U32.is_lt(f_source_begin(old), f_source_end(source)), u => "overlapping source intervals", u => fp_source_pairs(source, rest)))

@unsafe
def fp_source_inputs(sources, seen):
  match sources:
    case Nil{}: ""
    case Con{head, rest}:
      +error = fp_source_validate(head, seen)
      f_choose(String, String.is_empty(error), u => fp_source_inputs(rest, Con{head, seen}), u => error)

@unsafe
def fp_source_limit(sources, limit):
  match sources:
    case Nil{}: limit
    case Con{head, rest}: fp_source_limit(rest, norm_max(limit, f_source_end(head)))

@unsafe
def fp_source_prior(path, sources):
  match sources:
    case Nil{}: FSource{"", "", ""}
    case Con{head, rest}: f_choose(FSource, String.eq(path, f_source_path(head)), u => head, u => fp_source_prior(path, rest))

@unsafe
def fp_index_sources(sources, seen, next):
  match sources:
    case Nil{}: FPSourceSet{List.reverse(&2,FSource,seen), ""}
    case Con{head, rest}:
      f_choose(FPSourceSet, U32.is_gt(f_source_begin(head), 0), u => fp_index_sources(rest, Con{head, seen}, next), u => fp_index_one(head, rest, seen, next, fp_source_prior(f_source_path(head), seen)))

@unsafe
def fp_index_one(source, rest, seen, next, prior):
  f_choose(FPSourceSet, U32.is_gt(f_source_begin(prior), 0),
    u => fp_index_sources(rest, Con{FLocatedSource{FSource{f_source_name(source), f_source_path(source), f_source_text(source)}, f_source_begin(prior), f_source_end(prior)}, seen}, next),
    u => fp_index_fresh(source, rest, seen, next, fp_units(f_source_text(source), 0)))

@unsafe
def fp_index_fresh(source, rest, seen, next, size):
  f_choose(FPSourceSet, U32.is_lt(size, U32.sub(4294967295, next)),
    u => fp_index_sources(rest, Con{FLocatedSource{FSource{f_source_name(source), f_source_path(source), f_source_text(source)}, next, U32.add(next, U32.add(size, 1))}, seen}, U32.add(next, U32.add(size, 1))),
    u => FPSourceSet{Nil{}, "source interval overflow"})

@unsafe
def fp_origins(sources):
  match sources:
    case Nil{}: Nil{}
    case Con{head, rest}: Con{DSourceOrigin{f_source_text(head), f_source_begin(head), f_source_end(head)}, fp_origins(rest)}

@unsafe
def fp_located(sources):
  match sources:
    case Nil{}: True{}
    case Con{head, rest}: U32.is_gt(f_source_begin(head), 0) && fp_located(rest)

@unsafe
def f_load_origins(+main: String, +sources: List<&2,FSource>) -> FProvenance:
  f_load_origins_for(main, sources, "")

@unsafe
def f_load_origins_for(+main: String, +sources: List<&2,FSource>, +definition: String) -> FProvenance:
  +error = fp_source_inputs(sources, Nil{})
  f_choose(FProvenance, String.is_empty(error), u => fp_load_indexed(main, fp_index_sources(sources, Nil{}, fp_source_limit(sources, 1))), u => FProvenance{FResult{Nil{}, error, Nil{}}, Nil{}})

@unsafe
def fp_load_indexed(main, inputs):
  match inputs:
    case FPSourceSet{sources, error}:
      f_choose(FProvenance, String.is_empty(error), u => fp_trace_ready(f_load_graph_trace(main, sources)), u => FProvenance{FResult{Nil{}, error, Nil{}}, Nil{}})

@unsafe
def fp_trace_ready(trace):
  match trace:
    case FLoadTrace{result, done, sources}:
      match result:
        case FResult{book, error, imports}:
          f_choose(FProvenance, Bool.not(String.is_empty(error)) || fp_defs_ranges(book, sources), u => FProvenance{result, fp_origins(sources)}, u => FProvenance{FResult{Nil{}, "invalid term source interval", Nil{}}, Nil{}})

# Rechecking result.book is required after the explicitly unlocated replay path.
@unsafe
def f_loaded_origins_for(+trace: FLoadTrace, +definition: String) -> FProvenance:
  match trace:
    case FLoadTrace{result, done, sources}:
      match result:
        case FResult{book, error, imports}:
          f_choose(FProvenance, Bool.not(String.is_empty(error)), u => FProvenance{result, Nil{}},
            u => f_choose(FProvenance, fp_located(sources),
              u => f_choose(FProvenance, String.is_empty(fp_source_inputs(sources, Nil{})), u => fp_trace_ready(trace), u => FProvenance{FResult{Nil{}, "invalid located trace source ownership", Nil{}}, Nil{}}),
              u => f_choose(FProvenance, List.is_empty(&2,KTerm,done), u => FProvenance{result, Nil{}}, u => f_load_origins_for(nm(terms_at(done, 0)), sources, definition))))

# Low-level loader inputs remain trusted ASTs. This source-aware boundary checks
# all ranges before it exposes origins; valid synthesized nodes are exactly 0/0.
law fp_range_owned:
  for +begin: U32
  for +end: U32
  for +sources: List<&2,FSource>
  Bool
law fp_terms_ranges:
  for +terms: List<&2,KTerm>
  for +sources: List<&2,FSource>
  Bool
law fp_defs_ranges:
  for +defs: List<&2,KDef>
  for +sources: List<&2,FSource>
  Bool

@unsafe
def fp_range_owned(begin, end, sources):
  match sources:
    case Nil{}: False{}
    case Con{head, rest}:
      f_choose(Bool, U32.is_gt(f_source_begin(head), 0) && U32.is_ge(begin, f_source_begin(head)) && U32.is_ge(end, begin) && U32.is_lt(end, f_source_end(head)), u => True{}, u => fp_range_owned(begin, end, rest))

@unsafe
def fp_terms_ranges(terms, sources):
  match terms:
    case Nil{}: True{}
    case Con{head, rest}:
      f_choose(Bool, f_choose(Bool, U32.is_eq(kb(head), 0), u => U32.is_eq(ke(head), 0), u => fp_range_owned(kb(head), ke(head), sources)), u => fp_terms_ranges(norm_join(ks(head), rest), sources), u => False{})

@unsafe
def fp_defs_ranges(defs, sources):
  match defs:
    case Nil{}: True{}
    case Con{head, rest}:
      f_choose(Bool, fp_terms_ranges([dt(head), dv(head)], sources), u => fp_defs_ranges(norm_defs_join(dc(head), rest), sources), u => False{})

# The first owned numeric range chooses the same file as diagnostic_locate.
@unsafe
def fp_module_env(+done: List<&2,KTerm>, +path: String) -> List<&2,KPName>:
  match done:
    case Nil{}: Nil{}
    case Con{head, rest}:
      kc(List<&2,KPName>, String.eq(nm(head), path), u => [KPFile{nm(kid(head, 0)), terms_tail(ks(head))}], u => fp_module_env(rest, path))

@unsafe
def fp_span_matches(+span: DSpan, +source: FSource, +begin: U32, +end: U32) -> Bool:
  match span:
    case DNoSpan{}: False{}
    case DSpan{text, left, right}: U32.is_eq(left, U32.sub(begin, f_source_begin(source))) && U32.is_eq(right, U32.sub(end, f_source_begin(source))) && String.eq(text, f_source_text(source))

@unsafe
def fp_range_env(+sources: List<&2,FSource>, +done: List<&2,KTerm>, +begin: U32, +end: U32, +span: DSpan) -> List<&2,KPName>:
  match sources:
    case Nil{}: Nil{}
    case Con{head, rest}:
      kc(List<&2,KPName>, U32.is_gt(f_source_begin(head), 0) && U32.is_ge(begin, f_source_begin(head)) && U32.is_ge(end, begin) && U32.is_lt(end, f_source_end(head)), u => kc(List<&2,KPName>, fp_span_matches(span, head, begin, end), u => fp_module_env(done, f_source_path(head)), u => Nil{}), u => fp_range_env(rest, done, begin, end, span))

@unsafe
def fp_diagnostic_env(+trail: List<&2,KTerm>, +sources: List<&2,FSource>, +done: List<&2,KTerm>, +span: DSpan) -> List<&2,KPName>:
  match trail:
    case Nil{}: Nil{}
    case Con{head, rest}:
      kc(List<&2,KPName>, U32.is_gt(kb(head), 0) && fp_range_owned(kb(head), ke(head), sources), u => fp_range_env(sources, done, kb(head), ke(head), span), u => fp_diagnostic_env(rest, sources, done, span))

@unsafe
def diagnostic_render_loaded(+result: DResult, +trace: FLoadTrace) -> String:
  match result trace:
    case DResult{error, book, DDiagnostic{expected, observed, has_observed, context, definition, span, note, trail}} FLoadTrace{loaded, done, sources}:
      kc(String, String.is_empty(error), u => "", u => kc(String, List.is_empty(&2,KTerm,trail), u => "Error: " ++ error, u => dg_render_parts_in(book, expected, observed, has_observed, List.reverse(&2,KTerm,context), definition, span, note, fp_diagnostic_env(trail, sources, done, span))))
