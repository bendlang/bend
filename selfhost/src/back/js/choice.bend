# Eliminate a validated Boolean-choice combinator only at a fully applied call
# with two literal lambda thunks. Names do not establish semantic identity.
law j_choice_definition:
  for +book: List<&2, KDef>
  for +d: KDef
  Bool

law j_choice_match:
  for +t: KTerm
  Bool

law j_choice_arm:
  for +t: KTerm
  for +first: Bool
  Bool

law j_choice_leaf:
  for +t: KTerm
  for +binder: U32
  Bool

law j_choice_after_type:
  for +book: List<&2, KDef>
  for +env: List<&2, KTerm>
  for +args: List<&2, KTerm>
  for +tail: Bool
  for +ty: KTerm
  String

law j_choice_after_bool:
  for +book: List<&2, KDef>
  for +env: List<&2, KTerm>
  for +args: List<&2, KTerm>
  for +tail: Bool
  for +condition: String
  for +ty: KTerm
  String

law j_choice_branch:
  for +book: List<&2, KDef>
  for +env: List<&2, KTerm>
  for +t: KTerm
  for +ty: KTerm
  for +tail: Bool
  String

@unsafe
def j_choice_call(
  +book: List<&2, KDef>,
  +spine: KTerm,
) -> Bool:
  kc(Bool, String.eq(tg(spine), "Call") && U32.is_eq(terms_len(ks(spine)), 4), u =>
    kc(Bool, String.eq(tg(j_strip(kid(spine, 2))), "Lam") && String.eq(tg(j_strip(kid(spine, 3))), "Lam") && String.eq(j_l_name(j_strip(kid(spine, 2))), "") && String.eq(j_l_name(j_strip(kid(spine, 3))), ""), u => j_choice_definition(book, lookup(book, nm(spine))), u => False{}), u => False{})

@unsafe
def j_choice_definition(book, d):
  kc(Bool, db(lookup(book, "Bool")) && db(lookup(book, "Unit")) && String.eq(tg(dt(d)), "All") && U32.is_eq(qt(dt(d)), 0) && String.eq(tg(j_strip(dv(d))), "Lam"),
    u => j_choice_match(j_strip(kid(j_strip(dv(d)), 0))), u => False{})

@unsafe
def j_choice_match(t):
  String.eq(tg(t), "Mat") && String.eq(nm(t), "True") && j_choice_arm(j_strip(kid(t, 0)), True{}) &&
  String.eq(tg(j_strip(kid(t, 1))), "Mat") && String.eq(nm(j_strip(kid(t, 1))), "False") &&
  j_choice_arm(j_strip(kid(j_strip(kid(t, 1)), 0)), False{}) && String.eq(tg(j_strip(kid(j_strip(kid(t, 1)), 1))), "Efq")

@unsafe
def j_choice_arm(t, first):
  String.eq(tg(t), "Lam") && String.eq(tg(j_strip(kid(t, 0))), "Lam") &&
  j_choice_leaf(j_strip(kid(j_strip(kid(t, 0)), 0)), kc(U32, first, u => ix(t), u => ix(j_strip(kid(t, 0)))))

@unsafe
def j_choice_leaf(t, binder):
  String.eq(tg(t), "App") && String.eq(tg(j_strip(kid(t, 0))), "Var") && U32.is_eq(ix(j_strip(kid(t, 0))), binder) &&
  String.eq(tg(j_strip(kid(t, 1))), "Ctr") && String.eq(nm(j_strip(kid(t, 1))), "Unit") && U32.is_eq(terms_len(ks(j_strip(kid(t, 1)))), 0)

@unsafe
def j_choice_emit(
  +book: List<&2, KDef>,
  +env: List<&2, KTerm>,
  +spine: KTerm,
  +tail: Bool,
) -> String:
  j_choice_after_type(book, env, ks(spine), tail, wnf(book, j_app_type(wnf(book, dt(lookup(book, nm(spine)))), kid(spine, 0))))

@unsafe
def j_choice_after_type(book, env, args, tail, ty):
  j_choice_after_bool(book, env, args, tail, j_expr(book, env, terms_at(args, 1), kid(ty, 0), False{}), wnf(book, j_app_type(ty, terms_at(args, 1))))

@unsafe
def j_choice_after_bool(book, env, args, tail, condition, ty):
  "(/* choice */" ++ condition ++ "?" ++ j_choice_branch(book, env, j_strip(terms_at(args, 2)), wnf(book, kid(ty, 0)), tail) ++ ":" ++
  j_choice_branch(book, env, j_strip(terms_at(args, 3)), wnf(book, kid(wnf(book, j_app_type(ty, terms_at(args, 2))), 0)), tail) ++ ")"

@unsafe
def j_choice_branch(book, env, t, ty, tail):
  "((" ++ j_local(ix(t)) ++ ")=>" ++ j_expr(book, Con{kt("Env", "", ix(t), 0, [kid(ty, 0)]), env}, kid(t, 0), subst(kid(ty, 1), ix(ty), var(nm(t), ix(t))), tail) ++ ")(" ++
  kc(String, U32.is_eq(qt(ty), 0), u => "null", u => "ctor(\"Unit\",[])") ++ ")"
