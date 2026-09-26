# Nat matcher chains operate on immediate words. Collect the typed Zero/Succ
# decision chain before lowering arms, avoiding one nested match/closure per
# peeled successor. Defaults receive exactly the remaining Nat at that level.
type NPLevel is Data:
  NPLevel{+zero: KTerm, +successor: KTerm, +fallback: KTerm, +hasZero: Bool, +hasSucc: Bool, +valid: Bool}

type NPRow is Data:
  NPRow{+index: U32, +body: KTerm, +residual: U32, +apply: Bool, +last: Bool}

law np_level_mat:
  for +term: KTerm
  for +zero: KTerm
  for +successor: KTerm
  for +hasZero: Bool
  for +hasSucc: Bool
  NPLevel
law np_collect_level:
  for +term: KTerm
  for +depth: U32
  for +built: List<&2,NPRow>
  for +level: NPLevel
  List<&2,NPRow>
law np_emit:
  for +book: List<&2,KDef>
  for +rows: List<&2,NPRow>
  for +word: String
  for +env: List<&2,NC_Binding>
  for +next: U32
  NC_Code
law np_emit_row:
  for +book: List<&2,KDef>
  for +row: NPRow
  for +rest: List<&2,NPRow>
  for +word: String
  for +env: List<&2,NC_Binding>
  for +next: U32
  NC_Code
law np_emit_done:
  for +book: List<&2,KDef>
  for +index: U32
  for +last: Bool
  for +rest: List<&2,NPRow>
  for +word: String
  for +env: List<&2,NC_Binding>
  for +code: NC_Code
  NC_Code
law np_emit_join:
  for +index: U32
  for +last: Bool
  for +word: String
  for +code: NC_Code
  for +tail: NC_Code
  NC_Code
law np_row_code:
  for +book: List<&2,KDef>
  for +body: KTerm
  for +residual: U32
  for +apply: Bool
  for +word: String
  for +env: List<&2,NC_Binding>
  for +next: U32
  NC_Code
law np_match_apply:
  for +book: List<&2,KDef>
  for +term: KTerm
  for +env: List<&2,NC_Binding>
  for +next: U32
  NC_Code
@unsafe
def np_supported(
  +term: KTerm,
) -> Bool:
  String.eq(tg(term), "Mat") && ((String.eq(nm(term), "Zero") && (U32.is_eq(ix(term), 0) || U32.is_eq(ix(term), 1))) || (String.eq(nm(term), "Succ") && (U32.is_eq(ix(term), 0) || U32.is_eq(ix(term), 2))))
@unsafe
def np_level(
  +term: KTerm,
  +zero: KTerm,
  +successor: KTerm,
  +hasZero: Bool,
  +hasSucc: Bool,
) -> NPLevel:
  nt_choose(NPLevel, String.eq(tg(term), "Mat"), u => np_level_mat(term, zero, successor, hasZero, hasSucc), u => NPLevel{zero, successor, term, hasZero, hasSucc, True{}})
@unsafe
def np_level_mat(term, zero, successor, hasZero, hasSucc):
  nt_choose(NPLevel, np_supported(term) && String.eq(nm(term), "Zero") && Bool.not(hasZero), u => np_level(kid(term, 1), kid(term, 0), successor, True{}, hasSucc), u =>
    nt_choose(NPLevel, np_supported(term) && String.eq(nm(term), "Succ") && Bool.not(hasSucc), u => np_level(kid(term, 1), zero, kid(term, 0), hasZero, True{}), u => NPLevel{zero, successor, term, hasZero, hasSucc, False{}}))
@unsafe
def np_collect(
  +term: KTerm,
  +depth: U32,
  +built: List<&2,NPRow>,
) -> List<&2,NPRow>:
  np_collect_level(term, depth, built, np_level(term, atom("Efq"), atom("Efq"), False{}, False{}))
@unsafe
def np_collect_level(term, depth, built, level):
  match level:
    case NPLevel{+zero, +successor, +fallback, +hasZero, +hasSucc, valid}:
      nt_choose(List<&2,NPRow>, valid && (hasZero || hasSucc),
        u => np_collect(nt_choose(KTerm, hasSucc, u => successor, u => fallback), nt_choose(U32, hasSucc, u => U32.inc(depth), u => depth), Con{NPRow{depth, nt_choose(KTerm, hasZero, u => zero, u => fallback), depth, Bool.not(hasZero), False{}}, built}),
        u => nt_reverse(NPRow, Con{NPRow{depth, term, depth, True{}, True{}}, built}, Nil{}))
@unsafe
def np_match_apply(book, term, env, next):
  np_emit(book, np_collect(kid(term, 0), 0, Nil{}), nc_word(ix(kid(term, 1)), env), nc_remove_env(env, ix(kid(term, 1))), next)
@unsafe
def np_emit(book, rows, word, env, next):
  match rows:
    case Nil{}:
      nc_fail("empty Nat pattern chain", next)
    case Con{row, rest}:
      np_emit_row(book, row, rest, word, env, next)
@unsafe
def np_emit_row(book, row, rest, word, env, next):
  match row:
    case NPRow{index, body, residual, apply, last}:
      np_emit_done(book, index, last, rest, word, env, np_row_code(book, body, residual, apply, word, env, next))
@unsafe
def np_emit_done(book, index, last, rest, word, env, code):
  nt_choose(NC_Code, last, u => NC_Code{"{\n" ++ nc_body(code) ++ "}\n", nc_segs(code), nc_fresh(code), nc_error(code)}, u => np_emit_join(index, last, word, code, np_emit(book, rest, word, env, nc_fresh(code))))
@unsafe
def np_emit_join(index, last, word, code, tail):
  NC_Code{"if (" ++ word ++ " == " ++ U32.show(index) ++ "ull) {\n" ++ nc_body(code) ++ "} else " ++ nc_body(tail), nt_append(N_Segment, nc_segs(code), nc_segs(tail)), nc_fresh(tail), nc_first_error(code, tail)}
@unsafe
def np_row_code(book, body, residual, apply, word, env, next):
  nt_choose(NC_Code, apply,
    u => nc_prepend("Term v_" ++ U32.show(nc_id(next)) ++ " = (" ++ word ++ " - " ++ U32.show(residual) ++ "ull);\n", nc_lower(book, app(body, var("", nc_id(next))), Con{nc_binding(nc_id(next)), env}, U32.inc(next))),
    u => nc_lower(book, body, env, next))

law np_can_match:
  for +term: KTerm
  Bool

@unsafe
def np_level_valid(
  +level: NPLevel,
) -> Bool:
  match level:
    case NPLevel{zero, successor, fallback, hasZero, hasSucc, valid}:
      valid && (hasZero || hasSucc)
@unsafe
def np_can_match(term):
  np_supported(term) && np_level_valid(np_level(term, atom("Efq"), atom("Efq"), False{}, False{}))
