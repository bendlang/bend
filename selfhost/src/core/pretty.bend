# Term readback and diagnostic rendering, implemented in Bend2.
# Precedence is encoded as upstream precedence + 1; zero is a top-level body.
type KPName is Data:
  KPName{name: String, id: U32, depth: U32}
  KPFile{+namespace: String, +aliases: List<&2,KTerm>}

type KPChain is Data:
  KPChain{items: List<&2, KTerm>, tail: KTerm}

law kp_index:
  for env: List<&2, KPName>
  for +id: U32
  U32

law kp_has_removed:
  for xs: List<&2, String>
  Bool

law kp_float_text:
  for +s: String
  String

law kp_digit:
  for +n: U32
  String

law kp_char_num:
  for n: Maybe<&2, U32>
  for +quote: U32
  Maybe<&2, String>

law kp_append:
  for a: Maybe<&2, String>
  for b: Maybe<&2, String>
  Maybe<&2, String>

law kp_array_join:
  for a: Maybe<&2, List<&2, KTerm>>
  for b: Maybe<&2, List<&2, KTerm>>
  Maybe<&2, List<&2, KTerm>>

law kp_ctor_number:
  for n: Maybe<&2, U32>
  for +t: KTerm
  for +p: U32
  for +env: List<&2, KPName>
  String

law kp_ctor_other:
  for +t: KTerm
  for +p: U32
  for +env: List<&2, KPName>
  String

law kp_ctor_char:
  for c: Maybe<&2, String>
  for +t: KTerm
  for +p: U32
  for +env: List<&2, KPName>
  String

law kp_ctor_string:
  for s: Maybe<&2, String>
  for +t: KTerm
  for +p: U32
  for +env: List<&2, KPName>
  String

law kp_ctor_array:
  for a: Maybe<&2, List<&2, KTerm>>
  for +t: KTerm
  for +env: List<&2, KPName>
  String

law kp_go:
  for +t: KTerm
  for +p: U32
  for +env: List<&2, KPName>
  String

law kp_go_tail:
  for +t: KTerm
  for +p: U32
  for +env: List<&2, KPName>
  String

law kp_go_last:
  for +t: KTerm
  for +p: U32
  for +env: List<&2, KPName>
  String

law kp_float_point:
  for s: String
  String

law kp_exists:
  for +A: KTerm
  for +b: KTerm
  for +p: U32
  for +env: List<&2, KPName>
  String

law kp_rewrite:
  for +t: KTerm
  for +p: U32
  for +env: List<&2, KPName>
  String

law kp_rewrite_motive:
  for +e: KTerm
  for +m: KTerm
  for +env: List<&2, KPName>
  String

law kp_let:
  for +t: KTerm
  for +p: U32
  for +env: List<&2, KPName>
  String

law kp_let_names:
  for ts: List<&2, KTerm>
  String

law kp_let_vals:
  for ts: List<&2, KTerm>
  for +env: List<&2, KPName>
  String

law kp_let_body:
  for ts: List<&2, KTerm>
  for +env: List<&2, KPName>
  String

@unsafe
def kp_eq(
  +a: String,
  +b: String,
) -> Bool:
  String.eq(a, b)

@unsafe
def kp_is(
  +t: KTerm,
  +tag: String,
  +name: String,
) -> Bool:
  kp_eq(tg(t), tag) && kp_eq(nm(t), name)

@unsafe
def kp_quant(
  +q: U32,
) -> String:
  kc(String, U32.is_eq(q, 0), u => "-", u => kc(String, U32.is_eq(q, 2), u => "+", u => ""))

@unsafe
def kp_join(
  xs: List<&2, String>,
  +sep: String,
) -> String:
  match xs:
    case Nil{}: ""
    case Con{h, Nil{}}: h
    case Con{h, t}: h ++ sep ++ kp_join(t, sep)

@unsafe
def kp_par(
  +s: String,
  +yes: Bool,
) -> String:
  kc(String, yes, u => "(" ++ s ++ ")", u => s)

# File context is separate from lexical binders and never changes their depth.
@unsafe
def kp_alias_name(+aliases: List<&2,KTerm>, +name: String) -> String:
  match aliases:
    case Nil{}: name
    case Con{im, rest}:
      kc(String, Bool.not(List.is_empty(&2,KTerm,ks(im))) && String.starts_with(name, nm(im) ++ "."), u => nm(kid(im, 0)) ++ String.drop(name, String.length(nm(im))), u => kp_alias_name(rest, name))

@unsafe
def kp_name(+env: List<&2,KPName>, +name: String) -> String:
  match env:
    case Nil{}: name
    case Con{KPName{n, id, depth}, rest}: kp_name(rest, name)
    case Con{KPFile{ns, aliases}, rest}:
      kc(String, Bool.not(String.is_empty(ns)) && String.starts_with(name, ns ++ "."), u => String.drop(name, String.length(ns ++ ".")), u => kp_alias_name(aliases, name))

@unsafe
def kp_show(
  +t: KTerm,
) -> String:
  kp_go(t, 0, Nil{})

@unsafe
def kp_scope(
  env: List<&2, KPName>,
  +id: U32,
  +name: String,
) -> String:
  match env:
    case Nil{}: name ++ "^" ++ U32.show(id)
    case Con{KPFile{ns, aliases}, tail}: kp_scope(tail, id, name)
    case Con{KPName{+n, +i, +depth}, +tail}:
      kc(String, kp_eq(n, name), u => kc(String, U32.is_eq(i, id), u => name, u => name ++ "^" ++ U32.show(kp_index(tail, id))), u => kp_scope(tail, id, name))

@unsafe
def kp_index(env, id):
  match env:
    case Nil{}: id
    case Con{KPFile{ns, aliases}, tail}: kp_index(tail, id)
    case Con{KPName{n, +i, +depth}, +tail}:
      kc(U32, U32.is_eq(i, id), u => depth, u => kp_index(tail, id))

@unsafe
def kp_depth(
  env: List<&2, KPName>,
) -> U32:
  match env:
    case Nil{}: 0
    case Con{KPFile{ns, aliases}, t}: kp_depth(t)
    case Con{KPName{n, i, depth}, t}: U32.add(1, kp_depth(t))

@unsafe
def kp_bound(
  env: List<&2, KPName>,
  +name: String,
) -> Bool:
  match env:
    case Nil{}: False{}
    case Con{KPFile{ns, aliases}, t}: kp_bound(t, name)
    case Con{KPName{n, i, depth}, t}: kp_eq(n, name) || kp_bound(t, name)

@unsafe
def kp_bind(
  +env: List<&2, KPName>,
  +t: KTerm,
) -> List<&2, KPName>:
  Con{KPName{nm(t), ix(t), kp_depth(env)}, env}

@unsafe
def kp_each(
  ts: List<&2, KTerm>,
  +p: U32,
  +env: List<&2, KPName>,
) -> List<&2, String>:
  match ts:
    case Nil{}: Nil{}
    case Con{h, t}: Con{kp_go(h, p, env), kp_each(t, p, env)}

@unsafe
def kp_chain(
  +t: KTerm,
  +name: String,
  +arity: U32,
  +acc: List<&2, KTerm>,
) -> KPChain:
  kc(KPChain, kp_is(t, "Ctr", name) && U32.is_eq(terms_len(ks(t)), arity),
    u => kp_chain(kid(t, U32.sub(arity, 1)), name, arity, Con{kid(t, 0), acc}),
    u => KPChain{List.reverse(&2, KTerm, acc), t})

@unsafe
def kp_spine(
  +t: KTerm,
  +acc: List<&2, KTerm>,
) -> KPChain:
  kc(KPChain, kp_eq(tg(t), "App"), u => kp_spine(kid(t, 0), Con{kid(t, 1), acc}), u => KPChain{acc, t})

@unsafe
def kp_application(
  s: KPChain,
  +p: U32,
  +env: List<&2, KPName>,
) -> String:
  match s:
    case KPChain{+xs, +h}: kc(String, kp_is(h, "Ref", "Exists") && U32.is_eq(terms_len(xs), 2) && kp_eq(tg(terms_at(xs, 1)), "Lam"), u => kp_exists(terms_at(xs, 0), terms_at(xs, 1), p, env), u => kp_go(h, 3, env) ++ "(" ++ kp_join(kp_each(xs, 1, env), ", ") ++ ")")

@unsafe
def kp_removed(
  xs: List<&2, String>,
  +env: List<&2, KPName>,
) -> String:
  match xs:
    case Nil{}: ""
    case Con{h, t}: " - " ++ kp_name(env, h) ++ "{}" ++ kp_removed(t, env)

@unsafe
def kp_adt(
  +t: KTerm,
  +p: U32,
  +env: List<&2, KPName>,
) -> String:
  kp_par(kp_name(env, nm(t)) ++ kc(String, U32.is_eq(terms_len(ks(t)), 0) && Bool.not(kp_has_removed(rm(t))), u => "", u => "<" ++ kp_join(kp_each(ks(t), 1, env), ", ") ++ ">") ++ kp_removed(rm(t), env), kp_has_removed(rm(t)) && U32.is_gt(p, 2))

@unsafe
def kp_has_removed(xs):
  match xs:
    case Nil{}: False{}
    case Con{h,t}: True{}

@unsafe
def kp_word(
  +t: KTerm,
  +bit: U32,
  +left: U32,
  +acc: U32,
) -> Maybe<&2, U32>:
  kc(Maybe<&2, U32>, U32.is_eq(left, 0),
    u => kc(Maybe<&2, U32>, kp_is(t, "Ctr", "WNil"), u => Some{acc}, u => None{}),
    u => kc(Maybe<&2, U32>, kp_is(t, "Ctr", "WCon") && U32.is_eq(terms_len(ks(t)), 2) && (kp_is(kid(t, 0), "Ctr", "True") || kp_is(kid(t, 0), "Ctr", "False")),
      u => kp_word(kid(t, 1), U32.shl(bit), U32.sub(left, 1), kc(U32, kp_is(kid(t, 0), "Ctr", "True"), u => U32.or(acc, bit), u => acc)), u => None{}))

@unsafe
def kp_number(
  +t: KTerm,
) -> Maybe<&2, U32>:
  kc(Maybe<&2, U32>, core_literal(t) && (String.eq(nm(t), "U32") || String.eq(nm(t), "F32")), u => Some{kl_number(t)}, u => kc(Maybe<&2, U32>, (kp_is(t, "Ctr", "U32") || kp_is(t, "Ctr", "F32")) && U32.is_eq(terms_len(ks(t)), 1), u => kp_word(kid(t, 0), 1, 32, 0), u => None{}))

@unsafe
def kp_float(
  n: U32,
) -> F32:
  match n:
    case U32{w}: F32{w}

@unsafe
def kp_float_show(
  +n: U32,
) -> String:
  kp_float_text(F32.show(kp_float(n)))

@unsafe
def kp_float_text(s):
  kc(String, String.contains(s, ".") || String.contains(s, "n"), u => s, u => kp_float_point(s))

@unsafe
def kp_hex(
  +n: U32,
) -> String:
  kc(String, U32.is_lt(n, 16), u => kp_digit(n), u => kp_hex(U32.div(n, 16)) ++ kp_digit(U32.mod(n, 16)))

@unsafe
def kp_digit(n):
  Char.show(Char.from_u32(kc(U32, U32.is_lt(n, 10), u => U32.add(n, 48), u => U32.add(n, 87))))

@unsafe
def kp_escape(
  +n: U32,
  +quote: U32,
) -> String:
  kc(String, U32.is_eq(n, 10), u => "\\n",
    u => kc(String, U32.is_eq(n, 9), u => "\\t",
    u => kc(String, U32.is_eq(n, 13), u => "\\r",
    u => kc(String, U32.is_eq(n, 0), u => "\\0",
    u => kc(String, U32.is_eq(n, 92), u => "\\\\",
    u => kc(String, U32.is_eq(n, quote), u => "\\" ++ Char.show(Char.from_u32(n)),
    u => kc(String, U32.is_lt(n, 32) || U32.is_eq(n, 127) || (U32.is_ge(n, 55296) && U32.is_le(n, 57343)) || U32.is_gt(n, 1114111), u => "\\u{" ++ kp_hex(n) ++ "}", u => Char.show(Char.from_u32(n)))))))))

@unsafe
def kp_char(
  +t: KTerm,
  +quote: U32,
) -> Maybe<&2, String>:
  kc(Maybe<&2, String>, kp_is(t, "Ctr", "Chr") && U32.is_eq(terms_len(ks(t)), 1), u => kp_char_num(kp_number(kid(t, 0)), quote), u => None{})

@unsafe
def kp_char_num(n, quote):
  match n:
    case None{}: None{}
    case Some{x}: Some{kp_escape(x, quote)}

@unsafe
def kp_string(
  +t: KTerm,
) -> Maybe<&2, String>:
  kc(Maybe<&2, String>, core_literal(t) && String.eq(nm(t), "String"), u => kp_string(core_literal_step(t)), u => kc(Maybe<&2, String>, kp_is(t, "Ctr", "SNil"), u => Some{""},
    u => kc(Maybe<&2, String>, kp_is(t, "Ctr", "SCon") && U32.is_eq(terms_len(ks(t)), 2), u => kp_append(kp_char(kid(t, 0), 34), kp_string(kid(t, 1))), u => None{})))

@unsafe
def kp_append(a, b):
  match a b:
    case Some{x} Some{y}: Some{x ++ y}
    case _ _: None{}

@unsafe
def kp_list(
  chain: KPChain,
  +p: U32,
  +env: List<&2, KPName>,
) -> String:
  match chain:
    case KPChain{+xs, +t}:
      kc(String, kp_is(t, "Ctr", "Nil"), u => "[" ++ kp_join(kp_each(xs, 1, env), ", ") ++ "]",
        u => kp_par(kp_join(kp_each(xs, 3, env), " <> ") ++ " <> " ++ kp_go(t, 2, env), U32.is_gt(p, 2)))

@unsafe
def kp_tuple(
  chain: KPChain,
  +env: List<&2, KPName>,
) -> String:
  match chain:
    case KPChain{xs, t}: "(" ++ kp_join(kp_each(xs, 1, env), ", ") ++ ", " ++ kp_go(t, 1, env) ++ ")"

@unsafe
def kp_nat(
  +t: KTerm,
  +n: Nat,
  +p: U32,
  +env: List<&2, KPName>,
) -> String:
  kc(String, core_nat(t), u => kc(String, Nat.is_le(n, U32.to_nat(U32.sub(4294967295, kl_number(t)))), u => Nat.show(Nat.add(n, U32.to_nat(kl_number(t)))) ++ "n", u => kp_par(Nat.show(n) ++ "n+" ++ U32.show(kl_number(t)) ++ "n", U32.is_gt(p, 2))), u =>
  kc(String, kp_is(t, "Ctr", "Zero"), u => Nat.show(n) ++ "n",
    u => kc(String, kp_is(t, "Ctr", "Succ") && U32.is_eq(terms_len(ks(t)), 1), u => kp_nat(kid(t, 0), Nat.add(n, 1n), p, env),
      u => kp_par(Nat.show(n) ++ "n+" ++ kp_go(t, 2, env), U32.is_gt(p, 2)))))

@unsafe
def kp_array(
  +t: KTerm,
) -> Maybe<&2, List<&2, KTerm>>:
  kc(Maybe<&2, List<&2, KTerm>>, kp_is(t, "Ctr", "ALeaf"), u => Some{[kid(t, 0)]},
    u => kc(Maybe<&2, List<&2, KTerm>>, kp_is(t, "Ctr", "ANode"), u => kp_array_join(kp_array(kid(t, 0)), kp_array(kid(t, 1))), u => None{}))

@unsafe
def kp_array_join(a, b):
  match a b:
    case Some{x} Some{y}: Some{List.append(&2, KTerm, x, y)}
    case _ _: None{}

@unsafe
def kp_ctor(
  +t: KTerm,
  +p: U32,
  +env: List<&2, KPName>,
) -> String:
  kp_ctor_number(kp_number(t), t, p, env)

@unsafe
def kp_ctor_number(n, t, p, env):
  match n:
    case Some{+x}: kc(String, kp_eq(nm(t), "F32"), u => kp_float_show(x), u => U32.show(x))
    case None{}: kp_ctor_other(t, p, env)

@unsafe
def kp_ctor_other(t, p, env):
  kc(String, kp_eq(nm(t), "Succ") || kp_eq(nm(t), "Zero"), u => kp_nat(t, 0n, p, env),
    u => kp_ctor_char(kp_char(t, 39), t, p, env))

@unsafe
def kp_ctor_char(c, t, p, env):
  match c:
    case Some{s}: "'" ++ s ++ "'"
    case None{}: kp_ctor_string(kp_string(t), t, p, env)

@unsafe
def kp_ctor_string(s, t, p, env):
  match s:
    case Some{x}: "\"" ++ x ++ "\""
    case None{}:
      kc(String, kp_eq(nm(t), "Con") || kp_eq(nm(t), "Nil"), u => kp_list(kp_chain(t, "Con", 2, Nil{}), p, env),
        u => kc(String, kp_eq(nm(t), "Tuple"), u => kp_tuple(kp_chain(t, "Tuple", 2, Nil{}), env), u => kp_ctor_array(kp_array(t), t, env)))

@unsafe
def kp_ctor_array(a, t, env):
  match a:
    case Some{xs}: "[" ++ kp_join(kp_each(xs, 1, env), ", ") ++ "]"
    case None{}: kp_name(env, nm(t)) ++ "{" ++ kp_join(kp_each(ks(t), 1, env), ", ") ++ "}"

@unsafe
def kp_matches(
  +t: KTerm,
  +env: List<&2, KPName>,
) -> String:
  kc(String, kp_eq(tg(t), "Mat"), u => kp_name(env, nm(t)) ++ ": " ++ kp_go(kid(t, 0), 2, env) ++ kc(String, kp_eq(tg(kid(t, 1)), "Efq"), u => "", u => "; " ++ kp_matches(kid(t, 1), env)), u => kp_go(t, 2, env))

@unsafe
def kp_go(t, p, env):
  kc(String, kp_eq(tg(t), "Var"), u => kp_scope(env, ix(t), nm(t)),
    u => kc(String, kp_eq(tg(t), "Ref"), u => kp_name(env, nm(t)) ++ kc(String, kp_bound(env, kp_name(env, nm(t))), u => "^", u => "") ++ kc(String, U32.is_eq(qt(t), 3), u => "!", u => ""),
    u => kc(String, kp_eq(tg(t), "Typ"), u => kc(String, kp_eq(tg(kid(t, 0)), "Qua") && U32.is_eq(qt(kid(t, 0)), 1), u => "Type", u => kc(String, kp_eq(tg(kid(t, 0)), "Qua") && U32.is_eq(qt(kid(t, 0)), 2), u => "Data", u => "Kind(" ++ kp_go(kid(t, 0), 1, env) ++ ")")),
    u => kc(String, kp_eq(tg(t), "Qnt"), u => "Quant",
    u => kc(String, kp_eq(tg(t), "Qua"), u => "&" ++ U32.show(qt(t)),
    u => kc(String, kp_eq(tg(t), "Min"), u => kp_par(kp_go(kid(t, 0), 3, env) ++ " <&> " ++ kp_go(kid(t, 1), 3, env), U32.is_gt(p, 2)),
    u => kc(String, kp_eq(tg(t), "All"), u => kp_par("@" ++ kp_quant(qt(t)) ++ nm(t) ++ ":" ++ kp_go(kid(t, 0), 3, env) ++ " -> " ++ kp_go(kid(t, 1), 2, kp_bind(env, t)), U32.is_gt(p, 2)),
    u => kc(String, kp_eq(tg(t), "Lam"), u => kp_par(kp_quant(qt(t)) ++ nm(t) ++ " => " ++ kp_go(kid(t, 0), 0, kp_bind(env, t)), U32.is_gt(p, 1)),
    u => kp_go_tail(t, p, env)))))))))

@unsafe
def kp_go_tail(t, p, env):
  kc(String, core_literal(t), u => kc(String, core_nat(t), u => U32.show(kl_number(t)) ++ "n", u => kp_ctor(core_literal_step(t), p, env)), u =>
  kc(String, kp_eq(tg(t), "App"), u => kp_application(kp_spine(t, Nil{}), p, env),
    u => kc(String, kp_eq(tg(t), "ADT"), u => kp_adt(t, p, env),
    u => kc(String, kp_eq(tg(t), "Ctr"), u => kp_ctor(t, p, env),
    u => kc(String, kp_eq(tg(t), "Mat"), u => "\\{" ++ kp_matches(t, env) ++ "}",
    u => kc(String, kp_eq(tg(t), "Efq"), u => "\\{}",
    u => kc(String, kp_eq(tg(t), "Eql"), u => "{" ++ kp_go(kid(t, 0), 2, env) ++ " == " ++ kp_go(kid(t, 1), 2, env) ++ " : " ++ kp_go(kid(t, 2), 2, env) ++ "}",
    u => kc(String, kp_eq(tg(t), "Rfl"), u => "{==}",
    u => kc(String, kp_eq(tg(t), "Hol"), u => "?" ++ nm(t),
    u => kc(String, kp_eq(tg(t), "Ann"), u => "{" ++ kp_go(kid(t, 0), 2, env) ++ " : " ++ kp_go(kid(t, 1), 2, env) ++ "}",
    u => kp_go_last(t, p, env)))))))))))

@unsafe
def kp_go_last(t, p, env):
  kc(String, kp_eq(tg(t), "Sub"), u => kp_go(kid(t, 1), p, env),
    u => kc(String, kp_eq(tg(t), "Rwt"), u => kp_rewrite(t, p, env),
    u => kc(String, kp_eq(tg(t), "Let"), u => kp_let(t, p, env),
    u => kc(String, kp_eq(tg(t), "Literal"), u => nm(t),
    u => "<" ++ tg(t) ++ ":" ++ nm(t) ++ ">"))))

@unsafe
def kp_float_point(s):
  match s:
    case SNil{}: ".0"
    case SCon{+h, +t}: kc(String, U32.is_eq(Char.to_u32(h), 101), u => ".0e" ++ t, u => Char.show(h) ++ kp_float_point(t))

@unsafe
def kp_exists(A, b, p, env):
  kp_par("&" ++ nm(b) ++ ":" ++ kp_go(A, 3, env) ++ " -> " ++ kp_go(kid(b, 0), 2, kp_bind(env, b)), U32.is_gt(p, 2))

@unsafe
def kp_rewrite(t, p, env):
  kp_par("%" ++ kp_rewrite_motive(kid(t, 0), kid(t, 1), env) ++ "; " ++ kp_go(kid(t, 2), 0, env), U32.is_gt(p, 1))

@unsafe
def kp_rewrite_motive(e, m, env):
  kc(String, kp_eq(tg(m), "Lam") && kp_eq(tg(kid(m, 0)), "Lam"), u => kc(String, kp_eq(nm(kid(m, 0)), ""), u => "", u => nm(kid(m, 0)) ++ "@") ++ kp_go(e, 2, env) ++ " : " ++ kp_go(kid(kid(m, 0), 0), 2, kp_bind(kp_bind(env, m), kid(m, 0))), u => kp_go(e, 2, env) ++ " : " ++ kp_go(m, 2, env))

@unsafe
def kp_let(t, p, env):
  kp_par(kp_let_names(ks(t)) ++ " = " ++ kp_let_vals(ks(t), env) ++ "; " ++ kp_let_body(ks(t), env), U32.is_gt(p, 0))

@unsafe
def kp_let_names(ts):
  match ts:
    case Nil{}: ""
    case Con{+h, +rest}: kc(String, U32.is_eq(terms_len(rest), 0), u => "", u => kp_quant(qt(h)) ++ nm(h) ++ kc(String, U32.is_eq(terms_len(rest), 1), u => "", u => " " ++ kp_let_names(rest)))

@unsafe
def kp_let_vals(ts, env):
  match ts:
    case Nil{}: ""
    case Con{+h, +rest}: kc(String, U32.is_eq(terms_len(rest), 0), u => "", u => kp_go(kid(h, 0), 2, env) ++ kc(String, U32.is_eq(terms_len(rest), 1), u => "", u => " " ++ kp_let_vals(rest, env)))

@unsafe
def kp_let_body(ts, env):
  match ts:
    case Nil{}: "<missing let body>"
    case Con{+h, +rest}: kc(String, U32.is_eq(terms_len(rest), 0), u => kp_go(h, 0, env), u => kp_let_body(rest, kp_bind(env, h)))
