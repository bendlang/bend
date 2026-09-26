import Base

# Materialize live template applications after source checking. Source templates
# stay available for conversion; their erased parameters never enter the ABI.
type KSpecialized is Data:
  KSpecialized{+book: List<&2, KDef>, +error: String}

type KSpecMemo is Data:
  KSpecMemo{+template: String, +key: String, +name: String, +active: Bool}

type KSpecState is Data:
  KSpecState{+book: List<&2, KDef>, +memo: List<&2, KSpecMemo>, +serial: U32, +fresh: U32, +error: String, +templates: List<&2, KDef>}

type KSpecTerm is Data:
  KSpecTerm{+state: KSpecState, +term: KTerm}

type KSpecTerms is Data:
  KSpecTerms{+state: KSpecState, +terms: List<&2, KTerm>}

law sp_finish:
  for +st: KSpecState
  KSpecialized

law sp_definitions:
  for +todo: List<&2, KDef>
  for +st: KSpecState
  KSpecState

law sp_definition_next:
  for +rest: List<&2, KDef>
  for +st: KSpecState
  for +d: KDef
  KSpecState

law sp_definition_done:
  for +rest: List<&2, KDef>
  for +d: KDef
  for +r: KSpecTerm
  KSpecState

law sp_keys:
  for +ts: List<&2, KTerm>
  String

law sp_name_keys:
  for +ns: List<&2, String>
  String

law sp_take_next:
  for +ts: List<&2, KTerm>
  for +n: U32
  List<&2, KTerm>

law sp_drop_next:
  for +ts: List<&2, KTerm>
  for +n: U32
  List<&2, KTerm>

law sp_shifts:
  for +ts: List<&2, KTerm>
  for +offset: U32
  List<&2, KTerm>

law sp_term:
  for +st: KSpecState
  for +t: KTerm
  for +ctx: List<&2, KTerm>
  for +goal: KTerm
  for +owner: String
  for +depth: U32
  KSpecTerm

law sp_annotation:
  for +t: KTerm
  for +r: KSpecTerm
  KSpecTerm

law sp_lambda:
  for +st: KSpecState
  for +t: KTerm
  for +ctx: List<&2, KTerm>
  for +goal: KTerm
  for +owner: String
  for +depth: U32
  KSpecTerm

law sp_single:
  for +t: KTerm
  for +r: KSpecTerm
  KSpecTerm

law sp_constructor:
  for +st: KSpecState
  for +t: KTerm
  for +ctx: List<&2, KTerm>
  for +goal: KTerm
  for +owner: String
  for +depth: U32
  KSpecTerm

law sp_ctor_done:
  for +t: KTerm
  for +r: KSpecTerms
  KSpecTerm

law sp_args:
  for +st: KSpecState
  for +xs: List<&2, KTerm>
  for +ctx: List<&2, KTerm>
  for +ty: KTerm
  for +owner: String
  for +depth: U32
  KSpecTerms

law sp_arg_head:
  for +st: KSpecState
  for +x: KTerm
  for +rest: List<&2, KTerm>
  for +ctx: List<&2, KTerm>
  for +ty: KTerm
  for +owner: String
  for +depth: U32
  KSpecTerms

law sp_arg_done:
  for +raw: KTerm
  for +rest: List<&2, KTerm>
  for +ctx: List<&2, KTerm>
  for +ty: KTerm
  for +owner: String
  for +depth: U32
  for +r: KSpecTerm
  KSpecTerms

law sp_cons:
  for +h: KTerm
  for +r: KSpecTerms
  KSpecTerms

law sp_spine:
  for +st: KSpecState
  for +t: KTerm
  for +xs: List<&2, KTerm>
  for +ctx: List<&2, KTerm>
  for +owner: String
  for +depth: U32
  KSpecTerm

law sp_head:
  for +st: KSpecState
  for +head: KTerm
  for +xs: List<&2, KTerm>
  for +ctx: List<&2, KTerm>
  for +owner: String
  for +depth: U32
  for +d: KDef
  KSpecTerm

law sp_regular_head:
  for +st: KSpecState
  for +head: KTerm
  for +xs: List<&2, KTerm>
  for +ctx: List<&2, KTerm>
  for +owner: String
  for +depth: U32
  KSpecTerm

law sp_regular_done:
  for +xs: List<&2, KTerm>
  for +ctx: List<&2, KTerm>
  for +owner: String
  for +depth: U32
  for +ty: KTerm
  for +r: KSpecTerm
  KSpecTerm

law sp_apply_result:
  for +head: KTerm
  for +r: KSpecTerms
  KSpecTerm

law sp_template:
  for +st: KSpecState
  for +d: KDef
  for +xs: List<&2, KTerm>
  for +ctx: List<&2, KTerm>
  for +owner: String
  for +depth: U32
  KSpecTerm

law sp_template_args:
  for +st: KSpecState
  for +d: KDef
  for +closed: List<&2, KTerm>
  for +rest: List<&2, KTerm>
  for +ctx: List<&2, KTerm>
  for +owner: String
  for +depth: U32
  KSpecTerm

law sp_template_checked:
  for +st: KSpecState
  for +d: KDef
  for +closed: List<&2, KTerm>
  for +rest: List<&2, KTerm>
  for +ctx: List<&2, KTerm>
  for +owner: String
  for +depth: U32
  for +checked: KChecked
  KSpecTerm

law sp_template_key:
  for +st: KSpecState
  for +d: KDef
  for +closed: List<&2, KTerm>
  for +rest: List<&2, KTerm>
  for +ctx: List<&2, KTerm>
  for +owner: String
  for +depth: U32
  for +key: String
  KSpecTerm

law sp_template_inst:
  for +rest: List<&2, KTerm>
  for +ctx: List<&2, KTerm>
  for +owner: String
  for +depth: U32
  for +r: KSpecTerm
  KSpecTerm

law sp_instance:
  for +st: KSpecState
  for +d: KDef
  for +xs: List<&2, KTerm>
  for +owner: String
  for +depth: U32
  for +key: String
  for +memo: KSpecMemo
  KSpecTerm

law sp_mint:
  for +st: KSpecState
  for +d: KDef
  for +xs: List<&2, KTerm>
  for +depth: U32
  for +key: String
  for +name: String
  KSpecTerm

law sp_apply_template:
  for +body: KTerm
  for +xs: List<&2, KTerm>
  KTerm

law sp_mint_type:
  for +st: KSpecState
  for +d: KDef
  for +xs: List<&2, KTerm>
  for +depth: U32
  for +key: String
  for +name: String
  for +ty: KTerm
  for +body: KTerm
  KSpecTerm

law sp_mint_body:
  for +d: KDef
  for +name: String
  for +ty: KTerm
  for +r: KSpecTerm
  KSpecTerm

law sp_validate:
  for +st: KSpecState
  for +d: KDef
  KSpecTerm

law sp_validate_done:
  for +st: KSpecState
  for +d: KDef
  for +error: String
  KSpecTerm

law sp_match:
  for +st: KSpecState
  for +t: KTerm
  for +ctx: List<&2, KTerm>
  for +goal: KTerm
  for +owner: String
  for +depth: U32
  KSpecTerm

law sp_match_type:
  for +st: KSpecState
  for +t: KTerm
  for +ctx: List<&2, KTerm>
  for +goal: KTerm
  for +owner: String
  for +depth: U32
  for +a: KTerm
  KSpecTerm

law sp_match_ctor:
  for +st: KSpecState
  for +t: KTerm
  for +ctx: List<&2, KTerm>
  for +goal: KTerm
  for +owner: String
  for +depth: U32
  for +a: KTerm
  for +ctr: KDef
  KSpecTerm

law sp_match_hit:
  for +t: KTerm
  for +ctx: List<&2, KTerm>
  for +goal: KTerm
  for +owner: String
  for +depth: U32
  for +a: KTerm
  for +r: KSpecTerm
  KSpecTerm

law sp_pair:
  for +t: KTerm
  for +h: KTerm
  for +r: KSpecTerm
  KSpecTerm

law sp_let:
  for +st: KSpecState
  for +xs: List<&2, KTerm>
  for +outer: List<&2, KTerm>
  for +ctx: List<&2, KTerm>
  for +goal: KTerm
  for +owner: String
  for +depth: U32
  KSpecTerms

law sp_let_binding:
  for +st: KSpecState
  for +h: KTerm
  for +rest: List<&2, KTerm>
  for +outer: List<&2, KTerm>
  for +ctx: List<&2, KTerm>
  for +goal: KTerm
  for +owner: String
  for +depth: U32
  for +ty: KTerm
  KSpecTerms

law sp_let_bound:
  for +h: KTerm
  for +rest: List<&2, KTerm>
  for +outer: List<&2, KTerm>
  for +ctx: List<&2, KTerm>
  for +goal: KTerm
  for +owner: String
  for +depth: U32
  for +ty: KTerm
  for +r: KSpecTerm
  KSpecTerms

law sp_let_body:
  for +r: KSpecTerm
  KSpecTerms

law sp_let_result:
  for +t: KTerm
  for +r: KSpecTerms
  KSpecTerm

law sp_rewrite:
  for +st: KSpecState
  for +t: KTerm
  for +ctx: List<&2, KTerm>
  for +owner: String
  for +depth: U32
  KSpecTerm

law sp_rewrite_type:
  for +st: KSpecState
  for +t: KTerm
  for +ctx: List<&2, KTerm>
  for +owner: String
  for +depth: U32
  for +eq: KTerm
  KSpecTerm

law sp_rewrite_done:
  for +t: KTerm
  for +r: KSpecTerm
  KSpecTerm

@unsafe
def specialized_book(
  +r: KSpecialized,
) -> List<&2, KDef>:
  match r:
    case KSpecialized{book, error}:
      book

@unsafe
def specialized_error(
  +r: KSpecialized,
) -> String:
  match r:
    case KSpecialized{book, error}:
      error

@unsafe
def sp_book(
  +st: KSpecState,
) -> List<&2, KDef>:
  match st:
    case KSpecState{book, memo, serial, fresh, error, templates}:
      book

@unsafe
def sp_memo(
  +st: KSpecState,
) -> List<&2, KSpecMemo>:
  match st:
    case KSpecState{book, memo, serial, fresh, error, templates}:
      memo

@unsafe
def sp_serial(
  +st: KSpecState,
) -> U32:
  match st:
    case KSpecState{book, memo, serial, fresh, error, templates}:
      serial

@unsafe
def sp_fresh(
  +st: KSpecState,
) -> U32:
  match st:
    case KSpecState{book, memo, serial, fresh, error, templates}:
      fresh

@unsafe
def sp_error(
  +st: KSpecState,
) -> String:
  match st:
    case KSpecState{book, memo, serial, fresh, error, templates}:
      error

@unsafe
def sp_state(
  +r: KSpecTerm,
) -> KSpecState:
  match r:
    case KSpecTerm{state, term}:
      state

@unsafe
def sp_value(
  +r: KSpecTerm,
) -> KTerm:
  match r:
    case KSpecTerm{state, term}:
      term

@unsafe
def sp_states(
  +r: KSpecTerms,
) -> KSpecState:
  match r:
    case KSpecTerms{state, terms}:
      state

@unsafe
def sp_values(
  +r: KSpecTerms,
) -> List<&2, KTerm>:
  match r:
    case KSpecTerms{state, terms}:
      terms

@unsafe
def sp_mtemplate(
  +m: KSpecMemo,
) -> String:
  match m:
    case KSpecMemo{template, key, name, active}:
      template

@unsafe
def sp_mkey(
  +m: KSpecMemo,
) -> String:
  match m:
    case KSpecMemo{template, key, name, active}:
      key

@unsafe
def sp_mname(
  +m: KSpecMemo,
) -> String:
  match m:
    case KSpecMemo{template, key, name, active}:
      name

@unsafe
def sp_active(
  +m: KSpecMemo,
) -> Bool:
  match m:
    case KSpecMemo{template, key, name, active}:
      active

@unsafe
def sp_fail(
  +st: KSpecState,
  +err: String,
) -> KSpecState:
  KSpecState{sp_book(st), sp_memo(st), sp_serial(st), sp_fresh(st), kc(String, String.eq(sp_error(st), ""), u => err, u => sp_error(st)), sp_templates(st)}

@unsafe
def sp_put(
  +st: KSpecState,
  +d: KDef,
) -> KSpecState:
  KSpecState{Con{d, index_remove(sp_book(st), dn(d))}, sp_memo(st), sp_serial(st), sp_fresh(st), sp_error(st), sp_templates(st)}

@unsafe
def sp_canonical(
  +book: List<&2, KDef>,
  +done: List<&2, KDef>,
) -> List<&2, KDef>:
  book_final_fast(book, done)

@unsafe
def specialize_book(
  +book: List<&2, KDef>,
) -> KSpecialized:
  sp_finish(sp_definitions(book, sp_initial(sp_canonical(book, Nil{}), norm_max_book(book))))

@unsafe
def sp_finish(st):
  KSpecialized{index_remove(sp_book(st), "$kernel.max-id"), sp_error(st)}

@unsafe
def sp_definitions(todo, st):
  match todo:
    case Nil{}:
      st
    case Con{d, rest}:
      kc(KSpecState, String.eq(sp_error(st), ""), u => sp_definition_next(rest, st, d), u => st)

@unsafe
def sp_definition_next(rest, st, d):
  kc(KSpecState, U32.is_gt(dx(d), 0) || String.eq(tg(dv(d)), "Absent") || String.eq(dk(d), "ADT") || Bool.not(sp_needed(sp_templates(st), dv(d))), u => sp_definitions(rest, st), u => sp_definition_done(rest, d, sp_term(st, dv(d), Nil{}, dt(d), dn(d), 0)))

@unsafe
def sp_definition_done(rest, d, r):
  sp_definitions(rest, sp_put(sp_state(r), KDef{dn(d), dk(d), da(d), dx(d), dt(d), sp_value(r), dc(d), db(d), du(d)}))

@unsafe
def sp_len(
  +s: String,
) -> U32:
  U32.from_nat(String.length(s))

@unsafe
def sp_key_string(
  +s: String,
) -> String:
  U32.show(sp_len(s)) ++ ":" ++ s

@unsafe
def term_key(
  +t: KTerm,
) -> String:
  sp_key_string(tg(t)) ++ sp_key_string(nm(t)) ++ U32.show(ix(t)) ++ ":" ++ U32.show(qt(t)) ++ "[" ++ sp_keys(ks(t)) ++ "][" ++ sp_name_keys(rm(t)) ++ "]"

@unsafe
def sp_keys(ts):
  match ts:
    case Nil{}:
      ""
    case Con{h, rest}:
      term_key(h) ++ sp_keys(rest)

@unsafe
def sp_name_keys(ns):
  match ns:
    case Nil{}:
      ""
    case Con{h, rest}:
      sp_key_string(h) ++ sp_name_keys(rest)

@unsafe
def sp_find(
  +ms: List<&2, KSpecMemo>,
  +name: String,
  +key: String,
) -> KSpecMemo:
  match ms:
    case Nil{}:
      KSpecMemo{"", "", "", False{}}
    case Con{h, rest}:
      kc(KSpecMemo, String.eq(sp_mtemplate(h), name) && String.eq(sp_mkey(h), key), u => h, u => sp_find(rest, name, key))

@unsafe
def sp_done_memo(
  +ms: List<&2, KSpecMemo>,
  +name: String,
) -> List<&2, KSpecMemo>:
  match ms:
    case Nil{}:
      Nil{}
    case Con{h, rest}:
      Con{kc(KSpecMemo, String.eq(sp_mname(h), name), u => KSpecMemo{sp_mtemplate(h), sp_mkey(h), sp_mname(h), False{}}, u => h), sp_done_memo(rest, name)}

@unsafe
def sp_take(
  +ts: List<&2, KTerm>,
  +n: U32,
) -> List<&2, KTerm>:
  kc(List<&2, KTerm>, U32.is_eq(n, 0), u => Nil{}, u => sp_take_next(ts, n))

@unsafe
def sp_take_next(ts, n):
  match ts:
    case Nil{}:
      Nil{}
    case Con{h, rest}:
      Con{h, sp_take(rest, U32.sub(n, 1))}

@unsafe
def sp_drop(
  +ts: List<&2, KTerm>,
  +n: U32,
) -> List<&2, KTerm>:
  kc(List<&2, KTerm>, U32.is_eq(n, 0), u => ts, u => sp_drop_next(ts, n))

@unsafe
def sp_drop_next(ts, n):
  match ts:
    case Nil{}:
      Nil{}
    case Con{h, rest}:
      sp_drop(rest, U32.sub(n, 1))

@unsafe
def sp_shift(
  +t: KTerm,
  +offset: U32,
) -> KTerm:
  KTerm{tg(t), nm(t), kc(U32, String.eq(tg(t), "Var") || String.eq(tg(t), "All") || String.eq(tg(t), "Lam") || String.eq(tg(t), "Bind") || String.eq(tg(t), "Sub"), u => U32.add(ix(t), offset), u => ix(t)), qt(t), sp_shifts(ks(t), offset), rm(t)}

@unsafe
def sp_shifts(ts, offset):
  match ts:
    case Nil{}:
      Nil{}
    case Con{h, rest}:
      Con{sp_shift(h, offset), sp_shifts(rest, offset)}

@unsafe
def sp_type(
  +st: KSpecState,
  +t: KTerm,
  +ctx: List<&2, KTerm>,
  +owner: String,
) -> KTerm:
  cy(infer(KEnv{sp_book(st), owner, ref(owner), 0, Nil{}, True{}}, ctx, t, 0, Nil{}))

@unsafe
def sp_term(st, t, ctx, goal, owner, depth):
  kc(KSpecTerm, Bool.not(String.eq(sp_error(st), "")), u => KSpecTerm{st, t},
   u => kc(KSpecTerm, String.eq(tg(t), "App") || String.eq(tg(t), "Ref"), u => sp_spine(st, t, Nil{}, ctx, owner, depth),
   u => kc(KSpecTerm, String.eq(tg(t), "Ann"), u => sp_annotation(t, sp_term(st, kid(t, 0), ctx, kid(t, 1), owner, depth)),
   u => kc(KSpecTerm, String.eq(tg(t), "Lam"), u => sp_lambda(st, t, ctx, wnf(sp_book(st), goal), owner, depth),
   u => kc(KSpecTerm, String.eq(tg(t), "Mat"), u => sp_match(st, t, ctx, wnf(sp_book(st), goal), owner, depth),
   u => kc(KSpecTerm, String.eq(tg(t), "Ctr"), u => sp_constructor(st, t, ctx, wnf(sp_book(st), goal), owner, depth),
   u => kc(KSpecTerm, String.eq(tg(t), "Let"), u => sp_let_result(t, sp_let(st, ks(t), ctx, ctx, goal, owner, depth)),
   u => kc(KSpecTerm, String.eq(tg(t), "Rwt"), u => sp_rewrite(st, t, ctx, owner, depth),
   u => KSpecTerm{st, t}))))))))

@unsafe
def sp_annotation(t, r):
  KSpecTerm{sp_state(r), KTerm{tg(t), nm(t), ix(t), qt(t), Con{sp_value(r), Con{kid(t, 1), Nil{}}}, rm(t)}}

@unsafe
def sp_lambda(st, t, ctx, goal, owner, depth):
  sp_single(t, sp_term(st, kid(t, 0), ctx_bind(ctx, ix(t), qt(goal), nm(t), kid(goal, 0)), subst(kid(goal, 1), ix(goal), var(nm(t), ix(t))), owner, depth))

@unsafe
def sp_single(t, r):
  KSpecTerm{sp_state(r), KTerm{tg(t), nm(t), ix(t), qt(t), Con{sp_value(r), Nil{}}, rm(t)}}

@unsafe
def sp_constructor(st, t, ctx, goal, owner, depth):
  sp_ctor_done(t, sp_args(st, ks(t), ctx, tele_fill(sp_book(st), dt(lookup(dc(lookup(sp_book(st), nm(goal))), nm(t))), ks(goal)), owner, depth))

@unsafe
def sp_ctor_done(t, r):
  KSpecTerm{sp_states(r), KTerm{tg(t), nm(t), ix(t), qt(t), sp_values(r), rm(t)}}

@unsafe
def sp_args(st, xs, ctx, ty, owner, depth):
  match xs:
    case Nil{}:
      KSpecTerms{st, Nil{}}
    case Con{x, rest}:
      sp_arg_head(st, x, rest, ctx, wnf(sp_book(st), ty), owner, depth)

@unsafe
def sp_arg_head(st, x, rest, ctx, ty, owner, depth):
  sp_arg_done(x, rest, ctx, ty, owner, depth, kc(KSpecTerm, String.eq(tg(ty), "All") && U32.is_eq(qt(ty), 0), u => KSpecTerm{st, x}, u => sp_term(st, x, ctx, kid(ty, 0), owner, depth)))

@unsafe
def sp_arg_done(raw, rest, ctx, ty, owner, depth, r):
  sp_cons(sp_value(r), sp_args(sp_state(r), rest, ctx, subst(kid(ty, 1), ix(ty), raw), owner, depth))

@unsafe
def sp_cons(h, r):
  KSpecTerms{sp_states(r), Con{h, sp_values(r)}}

@unsafe
def sp_spine(st, t, xs, ctx, owner, depth):
  kc(KSpecTerm, String.eq(tg(t), "App"), u => sp_spine(st, kid(t, 0), Con{kid(t, 1), xs}, ctx, owner, depth), u => sp_head(st, t, xs, ctx, owner, depth, lookup(sp_book(st), nm(strip(t)))))

@unsafe
def sp_head(st, head, xs, ctx, owner, depth, d):
  kc(KSpecTerm, String.eq(tg(strip(head)), "Ref") && U32.is_gt(dx(d), 0), u => sp_template(st, d, xs, ctx, owner, depth), u => sp_regular_head(st, head, xs, ctx, owner, depth))

@unsafe
def sp_regular_head(st, head, xs, ctx, owner, depth):
  sp_regular_done(xs, ctx, owner, depth, sp_type(st, head, ctx, owner), kc(KSpecTerm, String.eq(tg(head), "Ref"), u => KSpecTerm{st, head}, u => sp_term(st, head, ctx, sp_type(st, head, ctx, owner), owner, depth)))

@unsafe
def sp_regular_done(xs, ctx, owner, depth, ty, r):
  sp_apply_result(sp_value(r), sp_args(sp_state(r), xs, ctx, ty, owner, depth))

@unsafe
def sp_apply_result(head, r):
  KSpecTerm{sp_states(r), norm_apply(head, sp_values(r))}

@unsafe
def sp_template(st, d, xs, ctx, owner, depth):
  kc(KSpecTerm, U32.is_lt(terms_len(xs), dx(d)), u => KSpecTerm{sp_fail(st, "template requires all closed comptime arguments"), norm_apply(ref(dn(d)), xs)}, u => sp_template_args(st, d, sp_take(xs, dx(d)), sp_drop(xs, dx(d)), ctx, owner, depth))

@unsafe
def sp_template_args(st, d, closed, rest, ctx, owner, depth):
  sp_template_checked(st, d, closed, rest, ctx, owner, depth, template_args(KEnv{sp_book(st), owner, ref(owner), 0, Nil{}, du(d)}, dt(d), closed, dx(d)))

@unsafe
def sp_template_checked(st, d, closed, rest, ctx, owner, depth, checked):
  kc(KSpecTerm, good(checked), u => sp_template_key(st, d, closed, rest, ctx, owner, depth, sp_keys(closed)), u => KSpecTerm{sp_fail(st, ce(checked)), norm_apply(ref(dn(d)), norm_join(closed, rest))})

@unsafe
def sp_template_key(st, d, closed, rest, ctx, owner, depth, key):
  kc(KSpecTerm, U32.is_gt(sp_len(key), 32768), u => KSpecTerm{sp_fail(st, "a comptime argument must stop growing"), ref(dn(d))}, u => sp_template_inst(rest, ctx, owner, depth, sp_instance(st, d, closed, owner, depth, key, sp_find(sp_memo(st), dn(d), key))))

@unsafe
def sp_template_inst(rest, ctx, owner, depth, r):
  sp_apply_result(sp_value(r), sp_args(sp_state(r), rest, ctx, dt(lookup(sp_book(sp_state(r)), nm(sp_value(r)))), owner, depth))

@unsafe
def sp_instance(st, d, xs, owner, depth, key, memo):
  kc(KSpecTerm, Bool.not(String.eq(sp_mname(memo), "")),
   u => kc(KSpecTerm, sp_active(memo) && Bool.not(String.eq(sp_mname(memo), owner)), u => KSpecTerm{sp_fail(st, "nondecreasing cross-instance template recursion"), ref(sp_mname(memo))}, u => KSpecTerm{st, ref(sp_mname(memo))}),
   u => kc(KSpecTerm, U32.is_ge(depth, 64), u => KSpecTerm{sp_fail(st, "template instantiation exceeds 64 levels"), ref(dn(d))}, u => sp_mint(st, d, xs, U32.add(depth, 1), key, dn(d) ++ "~" ++ U32.show(sp_serial(st)))))

@unsafe
def sp_mint(st, d, xs, depth, key, name):
  sp_mint_type(st, d, xs, depth, key, name, tele_fill(sp_book(st), sp_shift(dt(d), sp_fresh(st)), xs), sp_apply_template(sp_shift(dv(d), sp_fresh(st)), xs))

@unsafe
def sp_apply_template(body, xs):
  match xs:
    case Nil{}:
      body
    case Con{h, rest}:
      sp_apply_template(kapply(body, h), rest)

@unsafe
def sp_mint_type(st, d, xs, depth, key, name, ty, body):
  sp_mint_body(d, name, ty, sp_term(KSpecState{Con{KDef{name, "Def", U32.sub(da(d), dx(d)), 0, ty, atom("Absent"), Nil{}, False{}, du(d)}, sp_stamp(sp_book(st), U32.add(sp_fresh(st), norm_max(norm_max_term(dt(d)), norm_max_term(dv(d)))))}, Con{KSpecMemo{dn(d), key, name, True{}}, sp_memo(st)}, U32.add(sp_serial(st), 1), U32.add(U32.add(sp_fresh(st), norm_max(norm_max_term(dt(d)), norm_max_term(dv(d)))), 1), sp_error(st), sp_templates(st)}, body, Nil{}, ty, name, depth))

@unsafe
def sp_mint_body(d, name, ty, r):
  sp_validate(sp_state(r), KDef{name, "Def", U32.sub(da(d), dx(d)), 0, ty, sp_value(r), Nil{}, False{}, du(d)})

@unsafe
def sp_validate(st, d):
  kc(KSpecTerm, String.eq(sp_error(st), ""), u => sp_validate_done(st, d, check_definition(sp_book(st), d)), u => KSpecTerm{st, ref(dn(d))})

@unsafe
def sp_validate_done(st, d, error):
  kc(KSpecTerm, String.eq(error, ""), u => KSpecTerm{KSpecState{Con{d, index_remove(sp_book(st), dn(d))}, sp_done_memo(sp_memo(st), dn(d)), sp_serial(st), sp_fresh(st), sp_error(st), sp_templates(st)}, ref(dn(d))}, u => KSpecTerm{sp_fail(st, dn(d) ++ ": " ++ error), ref(dn(d))})

@unsafe
def sp_match(st, t, ctx, goal, owner, depth):
  sp_match_type(st, t, ctx, goal, owner, depth, wnf(sp_book(st), kid(goal, 0)))

@unsafe
def sp_match_type(st, t, ctx, goal, owner, depth, a):
  sp_match_ctor(st, t, ctx, goal, owner, depth, a, lookup(dc(lookup(sp_book(st), nm(a))), nm(t)))

@unsafe
def sp_match_ctor(st, t, ctx, goal, owner, depth, a, ctr):
  sp_match_hit(t, ctx, goal, owner, depth, a, sp_term(st, kid(t, 0), ctx, mat_goal(sp_book(st), goal, tele_fill(sp_book(st), dt(ctr), ks(a)), da(ctr), nm(t), Nil{}), owner, depth))

@unsafe
def sp_match_hit(t, ctx, goal, owner, depth, a, r):
  sp_pair(t, sp_value(r), sp_term(sp_state(r), kid(t, 1), ctx, all(qt(goal), nm(goal), ix(goal), KTerm{tg(a), nm(a), ix(a), qt(a), ks(a), Con{nm(t), rm(a)}}, kid(goal, 1)), owner, depth))

@unsafe
def sp_pair(t, h, r):
  KSpecTerm{sp_state(r), KTerm{tg(t), nm(t), ix(t), qt(t), Con{h, Con{sp_value(r), Nil{}}}, rm(t)}}

@unsafe
def sp_let(st, xs, outer, ctx, goal, owner, depth):
  match xs:
    case Nil{}:
      KSpecTerms{sp_fail(st, "let has no body"), Nil{}}
    case Con{h, rest}:
      kc(KSpecTerms, String.eq(tg(h), "Bind"), u => sp_let_binding(st, h, rest, outer, ctx, goal, owner, depth, sp_type(st, kid(h, 0), outer, owner)), u => sp_let_body(sp_term(st, h, ctx, goal, owner, depth)))

@unsafe
def sp_let_binding(st, h, rest, outer, ctx, goal, owner, depth, ty):
  sp_let_bound(h, rest, outer, ctx, goal, owner, depth, ty, kc(KSpecTerm, U32.is_eq(qt(h), 0), u => KSpecTerm{st, kid(h, 0)}, u => sp_term(st, kid(h, 0), outer, ty, owner, depth)))

@unsafe
def sp_let_bound(h, rest, outer, ctx, goal, owner, depth, ty, r):
  sp_cons(KTerm{tg(h), nm(h), ix(h), qt(h), Con{sp_value(r), Nil{}}, rm(h)}, sp_let(sp_state(r), rest, outer, ctx_bind(ctx, ix(h), qt(h), nm(h), ty), goal, owner, depth))

@unsafe
def sp_let_body(r):
  KSpecTerms{sp_state(r), Con{sp_value(r), Nil{}}}

@unsafe
def sp_let_result(t, r):
  sp_ctor_done(t, r)

@unsafe
def sp_rewrite(st, t, ctx, owner, depth):
  sp_rewrite_type(st, t, ctx, owner, depth, wnf(sp_book(st), sp_type(st, kid(t, 0), ctx, owner)))

@unsafe
def sp_rewrite_type(st, t, ctx, owner, depth, eq):
  sp_rewrite_done(t, sp_term(st, kid(t, 2), ctx, app(app(kid(t, 1), kid(eq, 0)), atom("Rfl")), owner, depth))

@unsafe
def sp_rewrite_done(t, r):
  KSpecTerm{sp_state(r), KTerm{tg(t), nm(t), ix(t), qt(t), Con{kid(t, 0), Con{kid(t, 1), Con{sp_value(r), Nil{}}}}, rm(t)}}


law sp_initial:
  for +book: List<&2, KDef>
  for +bound: U32
  KSpecState

law sp_stamp:
  for +book: List<&2, KDef>
  for +bound: U32
  List<&2, KDef>

law sp_needed:
  for +book: List<&2, KDef>
  for +t: KTerm
  Bool

law sp_neededs:
  for +book: List<&2, KDef>
  for +ts: List<&2, KTerm>
  Bool

@unsafe
def sp_initial(book, bound):
  KSpecState{sp_stamp(book, bound), Nil{}, 0, U32.add(bound, 1), "", sp_template_book(book)}

@unsafe
def sp_stamp(book, bound):
  Con{KDef{"$kernel.max-id", "BookBound", bound, 0, atom("Absent"), atom("Absent"), Nil{}, False{}, False{}}, index_remove(book, "$kernel.max-id")}

@unsafe
def sp_needed(book, t):
  kc(Bool, String.eq(tg(t), "Ref"), u => U32.is_gt(dx(lookup(book, nm(t))), 0), u => sp_neededs(book, ks(t)))

@unsafe
def sp_neededs(book, ts):
  match ts:
    case Nil{}:
      False{}
    case Con{h, rest}:
      kc(Bool, sp_needed(book, h), u => True{}, u => sp_neededs(book, rest))

law sp_templates:
  for +st: KSpecState
  List<&2, KDef>

law sp_template_book:
  for +book: List<&2, KDef>
  List<&2, KDef>

@unsafe
def sp_templates(st):
  match st:
    case KSpecState{book, memo, serial, fresh, error, templates}:
      templates

@unsafe
def sp_template_book(book):
  match book:
    case Nil{}:
      Nil{}
    case Con{h, rest}:
      kc(List<&2, KDef>, U32.is_gt(dx(h), 0), u => Con{h, sp_template_book(rest)}, u => sp_template_book(rest))
