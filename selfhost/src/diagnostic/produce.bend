import Base

# The chronological checker returns its verdict and original diagnostic together.
law dg_span_fields:
  for +s: String
  for +b0: U32
  for +e0: U32
  for +b: DSpan
  Bool

law dg_origin_found:
  for +origins: List<&2, DOrigin>
  for +name: String
  for +rest: List<&2, KTerm>
  for +found: DSpan
  DSpan

law check_book_diagnostic:
  for +book: List<&2, KDef>
  for +origins: List<&2, DOrigin>
  DResult

law dg_quant_error:
  for +message: String
  for +name: String
  for +allowed: U32
  for +used: U32
  KChecked

law dg_constructor_names:
  for +ds: List<&2, KDef>
  String

law dg_ctor_error:
  for +e: KEnv
  for +t: KTerm
  for +ty: KTerm
  for +ctr: KDef
  KChecked

law dg_adt_error:
  for +t: KTerm
  for +d: KDef
  KChecked

@unsafe
def dg_span_same(
  +a: DSpan,
  +b: DSpan,
) -> Bool:
  match a:
    case DNoSpan{}: False{}
    case DSpan{s, b0, e0}: dg_span_fields(s, b0, e0, b)

@unsafe
def dg_span_fields(s, b0, e0, b):
  match b:
    case DNoSpan{}: False{}
    case DSpan{t, b1, e1}: String.eq(s, t) && U32.is_eq(b0, b1) && U32.is_eq(e0, e1)

@unsafe
def dg_has_span(
  +s: DSpan,
) -> Bool:
  match s:
    case DNoSpan{}: False{}
    case DSpan{source, begin, end}: True{}

@unsafe
def dg_origin_scan(
  +origins: List<&2, DOrigin>,
  +name: String,
  +t: KTerm,
  +found: DSpan,
) -> DSpan:
  match origins:
    case Nil{}: found
    case Con{DOrigin{definition, term, source, begin, end, path}, rest}:
      kc(DSpan, String.eq(name, definition) && norm_exact(t, term), u => kc(DSpan, Bool.not(dg_has_span(found)) || dg_span_same(found, DSpan{source, begin, end}), u => dg_origin_scan(rest, name, t, DSpan{source, begin, end}), u => DNoSpan{}), u => dg_origin_scan(rest, name, t, found))

@unsafe
def dg_origin_trail(
  +origins: List<&2, DOrigin>,
  +name: String,
  +trail: List<&2, KTerm>,
) -> DSpan:
  match trail:
    case Nil{}: DNoSpan{}
    case Con{h, rest}: dg_origin_found(origins, name, rest, dg_origin_scan(origins, name, h, DNoSpan{}))

@unsafe
def dg_origin_found(origins, name, rest, found):
  kc(DSpan, dg_has_span(found), u => found, u => dg_origin_trail(origins, name, rest))

@unsafe
def diagnostic_locate(
  +diagnostic: DDiagnostic,
  +origins: List<&2, DOrigin>,
) -> DDiagnostic:
  match diagnostic:
    case DDiagnostic{expected, observed, has_observed, context, definition, span, note, trail}:
      DDiagnostic{expected, observed, has_observed, context, definition, kc(DSpan, dg_has_span(span), u => span, u => dg_origin_trail(origins, definition, trail)), note, trail}

@unsafe
def diagnostic_result_locate(
  +result: DResult,
  +origins: List<&2, DOrigin>,
) -> DResult:
  match result:
    case DResult{error, book, diagnostic}: DResult{error, book, diagnostic_locate(diagnostic, origins)}

@unsafe
def dg_finish(
  +error: String,
  +book: List<&2, KDef>,
  +diagnostic: DDiagnostic,
  +origins: List<&2, DOrigin>,
) -> DResult:
  DResult{error, book, diagnostic_locate(diagnostic, origins)}

@unsafe
def check_book_diagnostic(book, origins):
  dg_seed_books(book, Nil{}, origins, book_cached(Nil{}, norm_max_book(book)))

law dg_seed_books:
  for +book: List<&2, KDef>
  for +validated: List<&2, KDef>
  for +origins: List<&2, DOrigin>
  for +seed: List<&2, KDef>
  DResult

# The immutable empty cache seeds independent declaration and event indexes.
@unsafe
def dg_seed_books(book, validated, origins, seed):
  dg_prefix_seed(book, validated, check_declarations(book, seed), seed, book, origins)

@unsafe
def dg_quant_error(message, name, allowed, used):
  dg_bad_detail(message, dg_text(kp_quant(allowed) ++ name), dg_text(kc(String, U32.is_eq(used, 2), u => name ++ " (consumed more than once)", u => kp_quant(used) ++ name)))

@unsafe
def dg_constructor_names(ds):
  match ds:
    case Nil{}: ""
    case Con{d, rest}: dn(d) ++ kc(String, defs_empty(rest), u => "", u => ", " ++ dg_constructor_names(rest))

@unsafe
def dg_ctor_error(e, t, ty, ctr):
  kc(KChecked, Bool.not(String.eq(dk(ctr), "Absent")) && Bool.not(has_name(rm(ty), nm(t))), u => dg_bad_detail("constructor does not belong to goal or field count differs", dg_text(nm(t) ++ " with " ++ U32.show(da(ctr)) ++ kc(String, U32.is_eq(da(ctr), 1), u => " field", u => " fields")), t), u => kc(KChecked, String.eq(dg_family(cb(e), nm(t)), ""), u => dg_bad_detail("constructor does not belong to goal or field count differs", dg_text("a declared constructor (" ++ nm(ty) ++ " declares " ++ dg_constructor_names(dc(lookup(cb(e), nm(ty)))) ++ ")"), t), u => dg_bad_detail("constructor does not belong to goal or field count differs", ty, ref(dg_family(cb(e), nm(t))))))


# The cached prefix must have passed check_book for this exact compiler and
# source. The suffix uses the same authoritative event worker as a full check.
law check_book_diagnostic_from_exact_prefix:
  for +book: List<&2,KDef>
  for +validated: List<&2,KDef>
  for +origins: List<&2,DOrigin>
  DResult
law dg_prefix_seed:
  for +todo: List<&2,KDef>
  for +validated: List<&2,KDef>
  for +done: List<&2,KDef>
  for +seen: List<&2,KDef>
  for +original: List<&2,KDef>
  for +origins: List<&2,DOrigin>
  DResult
law dg_suffix_events:
  for +todo: List<&2,KDef>
  for +done: List<&2,KDef>
  for +seen: List<&2,KDef>
  for +original: List<&2,KDef>
  for +origins: List<&2,DOrigin>
  DResult
law dg_suffix_guard:
  for +rest: List<&2,KDef>
  for +done: List<&2,KDef>
  for +d: KDef
  for +seen: List<&2,KDef>
  for +original: List<&2,KDef>
  for +origins: List<&2,DOrigin>
  for +guard: String
  DResult
law dg_suffix_check:
  for +rest: List<&2,KDef>
  for +done: List<&2,KDef>
  for +d: KDef
  for +seen: List<&2,KDef>
  for +original: List<&2,KDef>
  for +origins: List<&2,DOrigin>
  for +checked: KChecked
  DResult
law dg_suffix_finish:
  for +done: List<&2,KDef>
  for +seen: List<&2,KDef>
  for +original: List<&2,KDef>
  for +origins: List<&2,DOrigin>
  for +error: String
  DResult

@unsafe
def check_book_diagnostic_from_exact_prefix(book, validated, origins):
  kc(DResult, exact_prefix(book, validated), u => dg_seed_books(book, validated, origins, book_cached(Nil{}, norm_max_book(book))), u => check_book_diagnostic(book, origins))
@unsafe
def dg_prefix_seed(todo, validated, done, seen, original, origins):
  match validated:
    case Nil{}: dg_suffix_events(todo, done, seen, original, origins)
    case Con{head, tail}:
      dg_prefix_step(todo, head, tail, done, seen, original, origins)
@unsafe
def dg_suffix_events(todo, done, seen, original, origins):
  match todo:
    case Nil{}: dg_suffix_finish(done, seen, original, origins, check_open(done))
    case Con{d, rest}: dg_suffix_guard(rest, done, d, seen, original, origins, event_error(seen, d, lookup(seen, dn(d))))
@unsafe
def dg_suffix_guard(rest, done, d, seen, original, origins, guard):
  kc(DResult, String.eq(guard, ""), u => dg_suffix_check(rest, done, d, seen, original, origins, check_definition_result(done, signature_mode(d, rest))), u => dg_finish(dn(d) ++ ": " ++ guard, done, dg_no_report(dn(d), guard), origins))
@unsafe
def dg_suffix_check(rest, done, d, seen, original, origins, checked):
  kc(DResult, good(checked), u => dg_suffix_events(rest, check_event_install(done, d, rest), book_put(seen, d), original, origins), u => dg_finish(dn(d) ++ ": " ++ ce(checked), book_put(done, declared(d)), dg_report(checked, dn(d)), origins))
@unsafe
def dg_suffix_finish(done, seen, original, origins, error):
  kc(DResult, String.eq(error, ""), u => DResult{"", original, dg_no_report("", "")}, u => dg_finish(error, done, dg_no_report("", error), origins))

law dg_prefix_step:
  for +todo: List<&2,KDef>
  for +head: KDef
  for +tail: List<&2,KDef>
  for +done: List<&2,KDef>
  for +seen: List<&2,KDef>
  for +original: List<&2,KDef>
  for +origins: List<&2,DOrigin>
  DResult
@unsafe
def dg_prefix_step(todo, head, tail, done, seen, original, origins):
  match todo:
    case Nil{}: check_book_diagnostic(original, origins)
    case Con{event, rest}: dg_prefix_seed(rest, tail, check_event_install(done, head, rest), book_put(seen, head), original, origins)

# The checker verdict stays unchanged; only rejection metadata differs.
@unsafe
def dg_adt_error(t, d):
  kc(KChecked, String.eq(dk(d), "ADT"), u => dg_bad_detail("unknown family or wrong parameter count", dg_text(nm(t) ++ " with " ++ U32.show(da(d)) ++ kc(String, U32.is_eq(da(d), 1), u => " parameter", u => " parameters")), t), u => dg_bad_message("unknown family or wrong parameter count", dg_text("a declared datatype (unknown: " ++ nm(t) ++ ")")))

# Compatibility projections and explicit capability for hosts using one verdict.
law dg_result_error:
  for +result: DResult
  String
@unsafe
def dg_result_error(result):
  match result:
    case DResult{error, book, diagnostic}: error
@unsafe
def compiler_check_result_abi() -> U32:
  1
