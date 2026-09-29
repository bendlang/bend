# Canonical pinned term_lower JSON, shared by memo identity and its size guard.
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

# Internal-only tags cannot pass the authoritative closed-argument check. Keep
# their complete shape distinct for direct API totality; never alias their kids.
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
