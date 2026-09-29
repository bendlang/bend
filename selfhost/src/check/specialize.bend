import Base

# Live instances use the ordinary checker. Output assembly only selects completed data.

type KChecked is Data:
  KChecked{+term: KTerm, +typ: KTerm, +uses: List<&2,KTerm>, +error: String}

type KSpecialized is Data:
  KSpecialized{+book: List<&2, KDef>, +error: KChecked}

type KSpecMemo is Data:
  KSpecMemo{+template: String, +key: String, +name: String, +active: Bool}

law sp_keys:
  for +ts: List<&2, KTerm>
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

law sp_apply_template:
  for +body: KTerm
  for +xs: List<&2, KTerm>
  KTerm

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
    case KSpecialized{book, payload}:
      sp_payload_error(payload)

@unsafe
def specialized_diagnostic(+r: KSpecialized) -> DResult:
  match r:
    case KSpecialized{book, payload}:
      +error = sp_payload_error(payload)
      DResult{error, book, dg_report_payload(sp_payload_term(payload), error, "")}

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
def sp_len(+s: String) -> U32:
  sk_width(s, 0)

@unsafe
def sk_width(+s: String, +n: U32) -> U32:
  match s:
    case SNil{}: n
    case SCon{c, rest}: sk_width(rest, U32.add(n, dg_units(c)))

@unsafe
def sk_quote(+s: String) -> String:
  "\"" ++ String.reverse(sk_escape(s, "")) ++ "\""

@unsafe
def sk_escape(+s: String, +acc: String) -> String:
  match s:
    case SNil{}: acc
    case SCon{c, rest}: sk_escape(rest, String.reverse(sk_char(c, Char.to_u32(c))) ++ acc)

@unsafe
def sk_char(+c: Char, +n: U32) -> String:
  match n:
    case 34: "\\\""
    case 92: "\\\\"
    case 8: "\\b"
    case 9: "\\t"
    case 10: "\\n"
    case 12: "\\f"
    case 13: "\\r"
    case other:
      kc(String, U32.is_lt(n, 32), u => "\\u00" ++ kc(String, U32.is_lt(n, 16), u => "0", u => "") ++ kp_hex(n),
        u => kc(String, U32.is_ge(n, 55296) && U32.is_le(n, 57343), u => "\\u" ++ kp_hex(n), u => Char.show(c)))

@unsafe
def sk_quant(+q: U32) -> String:
  "{\"$\":\"" ++ kc(String, U32.is_eq(q, 0), u => "None", u => kc(String, U32.is_eq(q, 2), u => "Many", u => "Lone")) ++ "\"}"

@unsafe
def term_key(+t: KTerm) -> String:
  sk_term(t, Nil{}, 0)

@unsafe
def sp_keys(ts):
  match ts:
    case Nil{}: ""
    case Con{head, rest}: term_key(head) ++ kc(String, List.is_empty(&2, KTerm, rest), u => "", u => "\n" ++ sp_keys(rest))

@unsafe
def sk_names(+names: List<&2,String>) -> String:
  match names:
    case Nil{}: ""
    case Con{head, rest}: sk_quote(head) ++ kc(String, List.is_empty(&2, String, rest), u => "", u => "," ++ sk_names(rest))

@unsafe
def sk_terms(+ts: List<&2,KTerm>, +env: List<&2,KPName>, +depth: U32) -> String:
  match ts:
    case Nil{}: ""
    case Con{head, rest}: sk_term(head, env, depth) ++ kc(String, List.is_empty(&2, KTerm, rest), u => "", u => "," ++ sk_terms(rest, env, depth))

@unsafe
def sk_var(+t: KTerm, +env: List<&2,KPName>) -> String:
  match env:
    case Nil{}: sk_variable(nm(t), ix(t))
    case Con{KPFile{ns, aliases}, rest}: sk_var(t, rest)
    case Con{KPName{name, id, depth}, rest}:
      kc(String, U32.is_eq(ix(t), id), u => sk_variable(name, depth), u => sk_var(t, rest))

@unsafe
def sk_variable(+name: String, +id: U32) -> String:
  "{\"$\":\"Var\",\"k\":" ++ sk_quote(name) ++ ",\"i\":" ++ kc(String, U32.is_eq(id, 4294967295), u => "-1", u => U32.show(id)) ++ "}"

@unsafe
def sk_term(+t: KTerm, +env: List<&2,KPName>, +depth: U32) -> String:
  kc(String, String.eq(tg(t), "Var"), u => kc(String, List.is_empty(&2, KTerm, ks(t)), u => sk_var(t, env), u => sk_term(kid(t, 0), env, depth)),
  u => kc(String, String.eq(tg(t), "Sub"), u => sk_term(subst(kid(t, 1), ix(t), kid(t, 0)), env, depth),
  u => sk_node(t, env, depth)))

@unsafe
def sk_node(+t: KTerm, +env: List<&2,KPName>, +depth: U32) -> String:
  kc(String, String.eq(tg(t), "Ref"), u => "{\"$\":\"Ref\",\"k\":" ++ sk_quote(nm(t)) ++ kc(String, U32.is_eq(qt(t), 3), u => ",\"b\":true", u => "") ++ "}",
  u => kc(String, core_literal(t), u => "{\"$\":\"Lit\",\"k\":" ++ sk_quote(nm(t)) ++ ",\"v\":" ++ kc(String, String.eq(nm(t), "String"), u => sk_quote(kl_text(t)), u => U32.show(kl_number(t))) ++ "}",
  u => kc(String, String.eq(tg(t), "Lam"), u => "{\"$\":\"Lam\",\"k\":" ++ sk_quote(nm(t)) ++ ",\"i\":" ++ U32.show(depth) ++ ",\"f\":" ++ sk_term(kid(t, 0), Con{KPName{nm(t), ix(t), depth}, env}, U32.inc(depth)) ++ kc(String, k_quantity_present(t), u => ",\"q\":" ++ sk_quant(qt(t)), u => "") ++ "}",
  u => kc(String, String.eq(tg(t), "All"), u => "{\"$\":\"All\",\"q\":" ++ sk_quant(qt(t)) ++ ",\"k\":" ++ sk_quote(nm(t)) ++ ",\"i\":" ++ U32.show(depth) ++ ",\"A\":" ++ sk_term(kid(t, 0), env, depth) ++ ",\"B\":" ++ sk_term(kid(t, 1), Con{KPName{nm(t), ix(t), depth}, env}, U32.inc(depth)) ++ "}",
  u => kc(String, String.eq(tg(t), "Let"), u => sk_let(ks(t), env, depth),
  u => kc(String, String.eq(tg(t), "ADT") || String.eq(tg(t), "Ctr"), u => "{\"$\":" ++ sk_quote(tg(t)) ++ ",\"k\":" ++ sk_quote(nm(t)) ++ ",\"x\":[" ++ sk_terms(ks(t), env, depth) ++ "]" ++ kc(String, String.eq(tg(t), "ADT"), u => ",\"r\":[" ++ sk_names(rm(t)) ++ "]", u => "") ++ "}",
  u => sk_other(t, env, depth)))))))

@unsafe
def sk_other(+t: KTerm, +env: List<&2,KPName>, +depth: U32) -> String:
  kc(String, String.eq(tg(t), "App"), u => sk_pair("App", "f", "x", t, env, depth),
  u => kc(String, String.eq(tg(t), "Min"), u => sk_pair("Min", "a", "b", t, env, depth),
  u => kc(String, String.eq(tg(t), "Ann"), u => sk_pair("Ann", "x", "T", t, env, depth),
  u => kc(String, String.eq(tg(t), "Typ"), u => "{\"$\":\"Typ\",\"g\":" ++ sk_term(kid(t, 0), env, depth) ++ "}",
  u => kc(String, String.eq(tg(t), "Qua"), u => "{\"$\":\"Qua\",\"q\":" ++ sk_quant(qt(t)) ++ "}",
  u => kc(String, String.eq(tg(t), "Mat"), u => "{\"$\":\"Mat\",\"k\":" ++ sk_quote(nm(t)) ++ ",\"h\":" ++ sk_term(kid(t, 0), env, depth) ++ ",\"m\":" ++ sk_term(kid(t, 1), env, depth) ++ "}",
  u => kc(String, String.eq(tg(t), "Eql"), u => sk_triple("Eql", "a", "b", "T", t, env, depth),
  u => kc(String, String.eq(tg(t), "Rwt"), u => sk_triple("Rwt", "e", "p", "f", t, env, depth),
  u => kc(String, String.eq(tg(t), "Hol"), u => "{\"$\":\"Hol\",\"k\":" ++ sk_quote(nm(t)) ++ "}",
  u => kc(String, String.eq(tg(t), "Qnt") || String.eq(tg(t), "Efq") || String.eq(tg(t), "Rfl"), u => "{\"$\":" ++ sk_quote(tg(t)) ++ "}",
  u => sk_internal(t, env, depth)))))))))))

@unsafe
def sk_internal(+t: KTerm, +env: List<&2,KPName>, +depth: U32) -> String:
  "{\"$\":\"Internal\",\"tag\":" ++ sk_quote(tg(t)) ++ ",\"name\":" ++ sk_quote(nm(t)) ++ ",\"id\":" ++ U32.show(ix(t)) ++ ",\"quant\":" ++ U32.show(qt(t)) ++ ",\"kids\":[" ++ sk_terms(ks(t), env, depth) ++ "],\"removed\":[" ++ sk_names(rm(t)) ++ "]}"

@unsafe
def sk_pair(+tag: String, +a: String, +b: String, +t: KTerm, +env: List<&2,KPName>, +depth: U32) -> String:
  "{\"$\":" ++ sk_quote(tag) ++ "," ++ sk_quote(a) ++ ":" ++ sk_term(kid(t, 0), env, depth) ++ "," ++ sk_quote(b) ++ ":" ++ sk_term(kid(t, 1), env, depth) ++ "}"

@unsafe
def sk_triple(+tag: String, +a: String, +b: String, +c: String, +t: KTerm, +env: List<&2,KPName>, +depth: U32) -> String:
  "{\"$\":" ++ sk_quote(tag) ++ "," ++ sk_quote(a) ++ ":" ++ sk_term(kid(t, 0), env, depth) ++ "," ++ sk_quote(b) ++ ":" ++ sk_term(kid(t, 1), env, depth) ++ "," ++ sk_quote(c) ++ ":" ++ sk_term(kid(t, 2), env, depth) ++ "}"

@unsafe
def sk_let(+xs: List<&2,KTerm>, +env: List<&2,KPName>, +depth: U32) -> String:
  "{\"$\":\"Let\",\"k\":[" ++ sk_let_field(xs, 0, env, depth, depth) ++ "],\"i\":[" ++ sk_let_field(xs, 1, env, depth, depth) ++ "],\"q\":[" ++ sk_let_field(xs, 2, env, depth, depth) ++ "],\"v\":[" ++ sk_let_field(xs, 3, env, depth, depth) ++ "],\"f\":" ++ sk_let_body(xs, env, depth) ++ "}"

@unsafe
def sk_let_field(+xs: List<&2,KTerm>, +field: U32, +env: List<&2,KPName>, +depth: U32, +id: U32) -> String:
  match xs:
    case Nil{}: ""
    case Con{head, rest}:
      kc(String, String.eq(tg(head), "Bind"),
        u => kc(String, U32.is_eq(field, 0), u => sk_quote(nm(head)),
          u => kc(String, U32.is_eq(field, 1), u => U32.show(id),
          u => kc(String, U32.is_eq(field, 2), u => sk_quant(qt(head)), u => sk_term(kid(head, 0), env, depth))))
          ++ kc(String, String.eq(tg(terms_at(rest, 0)), "Bind"), u => "," ++ sk_let_field(rest, field, env, depth, U32.inc(id)), u => ""),
        u => "")

@unsafe
def sk_let_body(+xs: List<&2,KTerm>, +env: List<&2,KPName>, +depth: U32) -> String:
  match xs:
    case Nil{}: "null"
    case Con{head, rest}:
      kc(String, String.eq(tg(head), "Bind"), u => sk_let_body(rest, Con{KPName{nm(head), ix(head), depth}, env}, U32.inc(depth)), u => sk_term(head, env, depth))

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
def sp_ordinal(
  +ms: List<&2, KSpecMemo>,
  +name: String,
) -> U32:
  match ms:
    case Nil{}: 0
    case Con{h, rest}: U32.add(kc(U32, String.eq(sp_mtemplate(h), name), u => 1, u => 0), sp_ordinal(rest, name))

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
  kc(KTerm, core_literal(t), u => t, u =>
    k_rebuild(t, nm(t), kc(U32, String.eq(tg(t), "Var") || String.eq(tg(t), "All") || String.eq(tg(t), "Lam") || String.eq(tg(t), "Bind") || String.eq(tg(t), "Sub"), u => U32.add(ix(t), offset), u => ix(t)), qt(t), sp_shifts(ks(t), offset), rm(t), kb(t), ke(t)))

@unsafe
def sp_shifts(ts, offset):
  match ts:
    case Nil{}:
      Nil{}
    case Con{h, rest}:
      Con{sp_shift(h, offset), sp_shifts(rest, offset)}

@unsafe
def sp_apply_template(body, xs):
  match xs:
    case Nil{}:
      body
    case Con{h, rest}:
      sp_apply_template(kapply(body, h), rest)

@unsafe
def sp_payload_error(+payload: KChecked) -> String:
  match payload:
    case KChecked{term, typ, uses, error}: error

@unsafe
def sp_payload_term(+payload: KChecked) -> KTerm:
  match payload:
    case KChecked{term, typ, uses, error}: term

@unsafe
def sp_assembled(+world: KWorld) -> List<&2,KDef>:
  book_final_reverse(kw_checked(world), Nil{})

@unsafe
def specialize_book(+book: List<&2,KDef>) -> KSpecialized:
  sp_public(dg_checking_result(dg_check_world(book)))

@unsafe
def sp_public(+r: KChecking) -> KSpecialized:
  KSpecialized{kc(List<&2,KDef>, good(r), u => sp_assembled(rw(r)), u => sp_source_book(kw_book(rw(r)))), KChecked{ct(r), cy(r), cs(r), ce(r)}}

@unsafe
def sp_source_book(+book: List<&2,KDef>) -> List<&2,KDef>:
  match book:
    case Nil{}: Nil{}
    case Con{h, rest}: kc(List<&2,KDef>, String.eq(dk(h), "BookCache") || String.eq(dk(h), "BookBound"), u => sp_source_book(rest), u => Con{h, sp_source_book(rest)})

@unsafe
def sp_live_checked(+e: KEnv, +ctx: List<&2,KTerm>, +head: KTerm, +sp: List<&2,KTerm>, +d: KDef, +r: KChecking) -> KChecking:
  kc(KChecking, good(r), u => sp_live_args(ke_world(e, rw(r)), ctx, head, sp, d, sp_take(sp, dx(d))), u => r)

@unsafe
def sp_live_key(+e: KEnv, +ctx: List<&2,KTerm>, +head: KTerm, +sp: List<&2,KTerm>, +d: KDef, +xs: List<&2,KTerm>, +key: String) -> KChecking:
  kc(KChecking, U32.is_gt(sp_len(key), 32768), u => sp_live_error(e, ctx, head, "a comptime argument must stop growing", "a ~ argument that stops growing"), u => sp_live_memo(e, ctx, head, sp, d, xs, key, sp_find(kw_memo(cw(e)), dn(d), key)))

@unsafe
def sp_live_error(+e: KEnv, +ctx: List<&2,KTerm>, +head: KTerm, +message: String, +expected: String) -> KChecking:
  dg_trace(e, ctx, head, atom("Absent"), dg_bad_detail(cw(e), message, dg_text(expected), head))

@unsafe
def sp_live_memo(+e: KEnv, +ctx: List<&2,KTerm>, +head: KTerm, +sp: List<&2,KTerm>, +d: KDef, +xs: List<&2,KTerm>, +key: String, +memo: KSpecMemo) -> KChecking:
  kc(KChecking, Bool.not(String.eq(sp_mname(memo), "")),
    u => kc(KChecking, sp_active(memo) && Bool.not(String.eq(sp_mname(memo), cn(e))), u => sp_live_error(e, ctx, head, "nondecreasing cross-instance template recursion", "a decreasing self-call (arguments are read left to right: each passed unchanged until one shrinks)"), u => sp_live_ref(cw(e), head, sp_mname(memo), dx(d))),
    u => kc(KChecking, U32.is_ge(cd(e), 64), u => sp_live_error(e, ctx, head, "template instantiation exceeds 64 levels", "a template that stops instantiating itself (64 levels at most)"), u => sp_live_fresh(e, ctx, head, d, xs, key, dn(d) ++ "~" ++ U32.show(sp_ordinal(kw_memo(cw(e)), dn(d))), kw_mint_floor(cw(e), Con{cl(e), norm_join(ctx, sp)}), norm_max(norm_max_term(dt(d)), norm_max_term(dv(d))))))

@unsafe
def sp_live_ref(+world: KWorld, +head: KTerm, +name: String, +consumed: U32) -> KChecking:
  KChecking{KTerm{"Ref", name, ix(head), qt(head), ks(head), rm(head), kb(head), ke(head)}, dt(lookup(kw_book(world), name)), Nil{}, "", world, consumed}

@unsafe
def sp_live_fresh(+e: KEnv, +ctx: List<&2,KTerm>, +head: KTerm, +d: KDef, +xs: List<&2,KTerm>, +key: String, +name: String, +bound: U32, +width: U32) -> KChecking:
  kc(KChecking, U32.is_lt(width, 4294967294) && U32.is_le(bound, U32.sub(4294967293, width)),
    u => sp_live_body(e, head, d, key, name, tele_fill(cb(e), sp_shift(dt(d), U32.add(bound, 1)), xs), sp_apply_template(sp_shift(dv(d), U32.add(bound, 1)), xs), U32.add(U32.add(bound, width), 2)),
    u => sp_live_error(e, ctx, head, "fresh binder space exhausted", "a representable fresh binder identity"))

@unsafe
def sp_live_body(+e: KEnv, +head: KTerm, +d: KDef, +key: String, +name: String, +ty: KTerm, +body: KTerm, +next: U32) -> KChecking:
  +inst: KDef = KDef{name, "Def", U32.sub(da(d), dx(d)), 0, ty, body, Nil{}, False{}, du(d)}
  +world: KWorld = KWorld{book_put(kw_bound_book(cb(e), U32.sub(next, 1)), declared(inst)), Con{KSpecMemo{dn(d), key, name, True{}}, kw_memo(cw(e))}, KFreshKnown{next}, kw_checked(cw(e))}
  sp_live_done(head, inst, dx(d), check_definition_body(world, inst, U32.add(cd(e), 1)))

@unsafe
def sp_live_done(+head: KTerm, +inst: KDef, +consumed: U32, +r: KChecking) -> KChecking:
  kc(KChecking, good(r), u => sp_live_ref(KWorld{book_put(kw_book(rw(r)), inst), sp_done_memo(kw_memo(rw(r)), dn(inst)), kw_fresh(rw(r)), Con{KDef{dn(inst), dk(inst), da(inst), dx(inst), dt(inst), ct(r), dc(inst), db(inst), du(inst)}, kw_checked(rw(r))}}, head, dn(inst), consumed), u => r)
@unsafe
def sp_live_args(+e: KEnv, +ctx: List<&2,KTerm>, +head: KTerm, +sp: List<&2,KTerm>, +d: KDef, +xs: List<&2,KTerm>) -> KChecking:
  sp_live_key(e, ctx, head, sp, d, xs, sp_keys(xs))
