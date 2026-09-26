import Base

# The chronological checker returns its verdict and original diagnostic together.
law dg_span_same:
  for +a: DSpan
  for +b: DSpan
  Bool

law dg_span_fields:
  for +s: String
  for +b0: U32
  for +e0: U32
  for +b: DSpan
  Bool

law dg_has_span:
  for +s: DSpan
  Bool

law dg_origin_scan:
  for +origins: List<&2, DOrigin>
  for +name: String
  for +t: KTerm
  for +found: DSpan
  DSpan

law dg_origin_trail:
  for +origins: List<&2, DOrigin>
  for +name: String
  for +trail: List<&2, KTerm>
  DSpan

law dg_origin_found:
  for +origins: List<&2, DOrigin>
  for +name: String
  for +rest: List<&2, KTerm>
  for +found: DSpan
  DSpan

law diagnostic_locate:
  for +diagnostic: DDiagnostic
  for +origins: List<&2, DOrigin>
  DDiagnostic

law diagnostic_result_locate:
  for +result: DResult
  for +origins: List<&2, DOrigin>
  DResult

law dg_finish:
  for +error: String
  for +book: List<&2, KDef>
  for +diagnostic: DDiagnostic
  for +origins: List<&2, DOrigin>
  DResult

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
def dg_span_same(a, b):
  match a:
    case DNoSpan{}: False{}
    case DSpan{s, b0, e0}: dg_span_fields(s, b0, e0, b)

@unsafe
def dg_span_fields(s, b0, e0, b):
  match b:
    case DNoSpan{}: False{}
    case DSpan{t, b1, e1}: String.eq(s, t) && U32.is_eq(b0, b1) && U32.is_eq(e0, e1)

@unsafe
def dg_has_span(s):
  match s:
    case DNoSpan{}: False{}
    case DSpan{source, begin, end}: True{}

@unsafe
def dg_origin_scan(origins, name, t, found):
  match origins:
    case Nil{}: found
    case Con{DOrigin{definition, term, source, begin, end, path}, rest}:
      kc(DSpan, String.eq(name, definition) && norm_exact(t, term), u => kc(DSpan, Bool.not(dg_has_span(found)) || dg_span_same(found, DSpan{source, begin, end}), u => dg_origin_scan(rest, name, t, DSpan{source, begin, end}), u => DNoSpan{}), u => dg_origin_scan(rest, name, t, found))

@unsafe
def dg_origin_trail(origins, name, trail):
  match trail:
    case Nil{}: DNoSpan{}
    case Con{h, rest}: dg_origin_found(origins, name, rest, dg_origin_scan(origins, name, h, DNoSpan{}))

@unsafe
def dg_origin_found(origins, name, rest, found):
  kc(DSpan, dg_has_span(found), u => found, u => dg_origin_trail(origins, name, rest))

@unsafe
def diagnostic_locate(diagnostic, origins):
  match diagnostic:
    case DDiagnostic{expected, observed, has_observed, context, definition, span, note, trail}:
      DDiagnostic{expected, observed, has_observed, context, definition, kc(DSpan, dg_has_span(span), u => span, u => dg_origin_trail(origins, definition, trail)), note, trail}

@unsafe
def diagnostic_result_locate(result, origins):
  match result:
    case DResult{error, book, diagnostic}: DResult{error, book, diagnostic_locate(diagnostic, origins)}

@unsafe
def dg_finish(error, book, diagnostic, origins):
  DResult{error, book, diagnostic_locate(diagnostic, origins)}

@unsafe
def check_book_diagnostic(book, origins):
  dg_suffix_events(book, book_cached(Nil{}, norm_max_book(book)), book, origins)

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
  for +original: List<&2,KDef>
  for +origins: List<&2,DOrigin>
  DResult
law dg_suffix_events:
  for +todo: List<&2,KDef>
  for +done: List<&2,KDef>
  for +original: List<&2,KDef>
  for +origins: List<&2,DOrigin>
  DResult
law dg_suffix_guard:
  for +rest: List<&2,KDef>
  for +done: List<&2,KDef>
  for +d: KDef
  for +original: List<&2,KDef>
  for +origins: List<&2,DOrigin>
  for +guard: String
  DResult
law dg_suffix_check:
  for +rest: List<&2,KDef>
  for +done: List<&2,KDef>
  for +d: KDef
  for +original: List<&2,KDef>
  for +origins: List<&2,DOrigin>
  for +checked: KChecked
  DResult
law dg_suffix_finish:
  for +done: List<&2,KDef>
  for +original: List<&2,KDef>
  for +origins: List<&2,DOrigin>
  for +error: String
  DResult

@unsafe
def check_book_diagnostic_from_exact_prefix(book, validated, origins):
  kc(DResult, exact_prefix(book, validated), u => dg_prefix_seed(book, validated, book_cached(Nil{}, norm_max_book(book)), book, origins), u => check_book_diagnostic(book, origins))
@unsafe
def dg_prefix_seed(todo, validated, done, original, origins):
  match validated:
    case Nil{}: dg_suffix_events(todo, done, original, origins)
    case Con{head, tail}:
      dg_prefix_step(todo, head, tail, done, original, origins)
@unsafe
def dg_suffix_events(todo, done, original, origins):
  match todo:
    case Nil{}: dg_suffix_finish(done, original, origins, check_open(done))
    case Con{d, rest}: dg_suffix_guard(rest, done, d, original, origins, event_error(done, d, lookup(done, dn(d))))
@unsafe
def dg_suffix_guard(rest, done, d, original, origins, guard):
  kc(DResult, String.eq(guard, ""), u => dg_suffix_check(rest, done, d, original, origins, check_definition_result(book_put(done, declared(d)), signature_mode(d, rest))), u => dg_finish(dn(d) ++ ": " ++ guard, done, dg_no_report(dn(d), guard), origins))
@unsafe
def dg_suffix_check(rest, done, d, original, origins, checked):
  kc(DResult, good(checked), u => dg_suffix_events(rest, book_put(done, d), original, origins), u => dg_finish(dn(d) ++ ": " ++ ce(checked), book_put(done, declared(d)), dg_report(checked, dn(d)), origins))
@unsafe
def dg_suffix_finish(done, original, origins, error):
  kc(DResult, String.eq(error, ""), u => DResult{"", original, dg_no_report("", "")}, u => dg_finish(error, done, dg_no_report("", error), origins))

law dg_prefix_step:
  for +todo: List<&2,KDef>
  for +head: KDef
  for +tail: List<&2,KDef>
  for +done: List<&2,KDef>
  for +original: List<&2,KDef>
  for +origins: List<&2,DOrigin>
  DResult
@unsafe
def dg_prefix_step(todo, head, tail, done, original, origins):
  match todo:
    case Nil{}: check_book_diagnostic(original, origins)
    case Con{event, rest}: dg_prefix_seed(rest, tail, book_put(done, head), original, origins)

# The checker verdict stays unchanged; only rejection metadata differs.
@unsafe
def dg_adt_error(t, d):
  kc(KChecked, String.eq(dk(d), "ADT"), u => dg_bad_detail("unknown family or wrong parameter count", dg_text(nm(t) ++ " with " ++ U32.show(da(d)) ++ kc(String, U32.is_eq(da(d), 1), u => " parameter", u => " parameters")), t), u => dg_bad_message("unknown family or wrong parameter count", dg_text("a declared datatype (unknown: " ++ nm(t) ++ ")")))

# Compatibility projections and explicit capability for hosts using one verdict.
law dg_result_error:
  for +result: DResult
  String
law compiler_check_result_abi:
  U32
@unsafe
def dg_result_error(result):
  match result:
    case DResult{error, book, diagnostic}: error
@unsafe
def compiler_check_result_abi():
  1
