import Base

law j_l_name:
  for +t: KTerm
  String

law j_l_names:
  for +names: List<&2, String>
  String

law j_l_capture:
  for +env: List<&2, KTerm>
  for +seen: List<&2, String>
  String

law j_l_deeps:
  for +ts: List<&2, KTerm>
  for +depth: U32
  Bool

law j_l_marks:
  for +ts: List<&2, KTerm>
  for +path: String
  for +depth: U32
  for +at: U32
  List<&2, KTerm>

law j_l_def:
  for +book: List<&2, KDef>
  for +d: KDef
  String

law j_l_definition:
  for +book: List<&2, KDef>
  for +d: KDef
  for +t: KTerm
  String

law j_l_walk:
  for +book: List<&2, KDef>
  for +env: List<&2, KTerm>
  for +t: KTerm
  for +ty: KTerm
  String

law j_l_children:
  for +book: List<&2, KDef>
  for +env: List<&2, KTerm>
  for +t: KTerm
  for +ty: KTerm
  String

law j_l_lam:
  for +book: List<&2, KDef>
  for +env: List<&2, KTerm>
  for +t: KTerm
  for +ty: KTerm
  String

law j_l_mat:
  for +book: List<&2, KDef>
  for +env: List<&2, KTerm>
  for +t: KTerm
  for +ty: KTerm
  String

law j_l_app:
  for +book: List<&2, KDef>
  for +env: List<&2, KTerm>
  for +t: KTerm
  for +ty: KTerm
  String

law j_l_fields:
  for +book: List<&2, KDef>
  for +env: List<&2, KTerm>
  for +ts: List<&2, KTerm>
  for +ty: KTerm
  String

law j_l_bindings:
  for +book: List<&2, KDef>
  for +env: List<&2, KTerm>
  for +ts: List<&2, KTerm>
  String


# JavaScript emission from the checked first-order core.
# Emission is Bend2; JavaScript only supplies primitive values and effects.
# Erased binders retain a null ABI slot, but their arguments are never evaluated.
@unsafe
def j_escape(
  +s: String,
) -> String:
  match s:
    case SNil{}:
      ""
    case SCon{c, t}:
      j_escape_char(c) ++ j_escape(t)

law j_escape_char:
  for +c: Char
  String

@unsafe
def j_escape_char(c):
  j_escape_char_on(c, Char.to_u32(c))

law j_escape_char_on:
  for +c: Char
  for +key: U32
  String

@unsafe
def j_escape_char_on(c, key):
  match key:
    case 34:
      "\\\""
    case 92:
      "\\\\"
    case 10:
      "\\n"
    case 13:
      "\\r"
    case 9:
      "\\t"
    case 0:
      "\\x00"
    case n:
      Char.show(Char.from_u32(n))

law j_quote:
  for +s: String
  String

@unsafe
def j_quote(s):
  "\"" ++ j_escape(s) ++ "\""

law j_local:
  for +id: U32
  String

@unsafe
def j_local(id):
  "x" ++ U32.show(id)

@unsafe
def j_env(
  +env: List<&2, KTerm>,
  +id: U32,
) -> KTerm:
  match env:
    case Nil{}:
      atom("Absent")
    case Con{h, rest}:
      kc(KTerm, U32.is_eq(ix(h), id), u => kid(h, 0), u => j_env(rest, id))

law j_type:
  for +book: List<&2, KDef>
  for +env: List<&2, KTerm>
  for +t: KTerm
  KTerm

@unsafe
def j_type(book, env, t):
  j_type_on(book, env, t, tg(t))

law j_type_on:
  for +book: List<&2, KDef>
  for +env: List<&2, KTerm>
  for +t: KTerm
  for +key: String
  KTerm

@unsafe
def j_type_on(book, env, t, key):
  kc(KTerm, String.eq(key, "Ann"), u => kid(t, 1), u => kc(KTerm, String.eq(key, "Var"), u => j_env(env, ix(t)), u => kc(KTerm, String.eq(key, "Ref"), u => dt(lookup(book, nm(t))), u => kc(KTerm, String.eq(key, "App"), u => j_app_type(wnf(book, j_type(book, env, kid(t, 0))), kid(t, 1)), u => atom("Absent")))))

law j_app_type:
  for +ty: KTerm
  for +arg: KTerm
  KTerm

@unsafe
def j_app_type(ty, arg):
  kc(KTerm, String.eq(tg(ty), "All"), u => subst(kid(ty, 1), ix(ty), arg), u => atom("Absent"))

@unsafe
def j_exprs(
  +book: List<&2, KDef>,
  +env: List<&2, KTerm>,
  +xs: List<&2, KTerm>,
) -> String:
  match xs:
    case Nil{}:
      ""
    case Con{h, rest}:
      j_expr(book, env, h, atom("Absent"), False{}) ++ j_exprs_tail(book, env, rest)

law j_exprs_tail:
  for +book: List<&2, KDef>
  for +env: List<&2, KTerm>
  for +xs: List<&2, KTerm>
  String

@unsafe
def j_exprs_tail(book, env, xs):
  match xs:
    case Nil{}:
      ""
    case Con{h, rest}:
      "," ++ j_expr(book, env, h, atom("Absent"), False{}) ++ j_exprs_tail(book, env, rest)

law j_expr:
  for +book: List<&2, KDef>
  for +env: List<&2, KTerm>
  for +t: KTerm
  for +ty: KTerm
  for +tail: Bool
  String

@unsafe
def j_expr(book, env, t, ty, tail):
  kc(String, (String.eq(tg(t), "Lam") || String.eq(tg(t), "Mat")) && Bool.not(String.eq(j_l_name(t), "")), u => "F[" ++ j_quote(j_l_name(t)) ++ "](" ++ j_l_capture(env, Nil{}) ++ ")", u => j_expr_private(book, env, t, ty, tail))

# Private nodes are created only by the bounded private-region plan. Ordinary
# types, arithmetic, arguments and parallel lets retain their shared emitter.
@unsafe
def j_expr_private(+book: List<&2,KDef>, +env: List<&2,KTerm>, +t: KTerm, +ty: KTerm, +tail: Bool) -> String:
  kc(String, String.eq(tg(t), "JSlot"), u => "$p" ++ U32.show(ix(t)), u =>
  kc(String, String.eq(tg(t), "JCall"), u => j_region_name(nm(t)) ++ "(" ++ j_apply_args(book, env, ks(t), dt(lookup(book, nm(t)))) ++ ")", u =>
  kc(String, String.eq(tg(t), "JReadCall"), u => j_region_name(nm(t)) ++ "$get(" ++ j_region_read_args(book, env, ks(t), dt(lookup(book, nm(t)))) ++ ")", u =>
  kc(String, String.eq(tg(t), "JNative"), u => j_region_native_emit(book, env, t), u =>
  kc(String, String.eq(tg(t), "JVector"), u => "[" ++ j_ctor_args(book, env, ks(t), j_region_local_fields(book, ty)) ++ "]", u =>
  kc(String, String.eq(tg(t), "JUnpack"), u => "((" ++ j_region_parameters(U32.inc(ix(t)), U32.inc(U32.add(ix(t), qt(t)))) ++ ")=>" ++
    j_expr(book, env, kid(t, 0), ty, tail) ++ ")(" ++ j_region_field_reads("$p" ++ U32.show(ix(t)) ++ kc(String, j_region_local_vector(book, kid(t, 1)), u => "", u => ".a"), 0, qt(t)) ++ ")", u =>
  kc(String, String.eq(tg(t), "JIf"), u => "(" ++ j_expr(book, env, kid(t, 0), kt("ADT", "Bool", 0, 0, Nil{}), False{}) ++ "?" ++
    j_expr(book, env, kid(t, 1), ty, tail) ++ ":" ++ j_expr(book, env, kid(t, 2), ty, tail) ++ ")", u => j_expr_on(book, env, t, ty, tail, tg(t)))))))))

@unsafe
def j_region_read_args(+book: List<&2,KDef>, +env: List<&2,KTerm>, +args: List<&2,KTerm>, +ty: KTerm) -> String:
  match args:
    case Nil{}: ""
    case Con{h, Nil{}}: j_apply_args(book, env, ks(j_strip(h)), dt(lookup(book, "Array.get")))
    case Con{h, rest}:
      +head = wnf(book, ty)
      j_expr(book, env, h, kid(head, 0), False{}) ++ "," ++ j_region_read_args(book, env, rest, j_app_type(head, h))

law j_expr_on:
  for +book: List<&2, KDef>
  for +env: List<&2, KTerm>
  for +t: KTerm
  for +ty: KTerm
  for +tail: Bool
  for +key: String
  String

@unsafe
def j_expr_on(book, env, t, ty, tail, key):
  kc(String, String.eq(key, "Var"), u => j_local(ix(t)), u => kc(String, String.eq(key, "Ref"), u => "get(G," ++ j_quote(nm(t)) ++ ")", u => kc(String, String.eq(key, "App"), u => j_apply(book, env, t, tail, wnf(book, j_type(book, env, kid(t, 0)))), u => kc(String, String.eq(key, "Ctr") || core_literal(t), u => j_constructor_mode(book, env, t, ty, tail), u => kc(String, String.eq(key, "Ann"), u => j_expr(book, env, kid(t, 0), kid(t, 1), tail), u => kc(String, String.eq(key, "Lam"), u => j_lambda(book, env, t, wnf(book, ty)), u => kc(String, String.eq(key, "Mat"), u => j_match(book, env, t, wnf(book, ty)), u => kc(String, String.eq(key, "Let"), u => j_let(book, env, ks(t), ty, tail), u => kc(String, String.eq(key, "Rwt"), u => j_expr(book, env, kid(t, 2), ty, tail), u => kc(String, String.eq(key, "Efq"), u => "fn(1,()=>bad(\"an absurd elimination\"))", u => kc(String, String.eq(key, "Hol"), u => "bad(\"cannot compile a hole\")", u => kc(String, String.eq(key, "ADT"), u => "({typeName:" ++ j_quote(nm(t)) ++ ",typeArgs:[" ++ j_exprs(book, env, ks(t)) ++ "]})", u => kc(String, String.eq(key, "Qua"), u => "({typeName:" ++ j_quote("&" ++ U32.show(qt(t))) ++ "})", u => kc(String, String.eq(key, "Typ"), u => "({typeName:\"Type\"})", u => kc(String, String.eq(key, "Rfl"), u => "({proof:true})", u => "null")))))))))))))))

law j_lambda:
  for +book: List<&2, KDef>
  for +env: List<&2, KTerm>
  for +t: KTerm
  for +ty: KTerm
  String

@unsafe
def j_lambda(book, env, t, ty):
  "fn(" ++ U32.show(j_lambda_count(t)) ++ ",function(a){" ++ j_lambda_code(book, env, t, ty, 0) ++ "})"

law j_lambda_count:
  for +t: KTerm
  U32

@unsafe
def j_lambda_count(t):
  kc(U32, String.eq(tg(t), "Ann"), u => j_lambda_count(kid(t, 0)), u => kc(U32, String.eq(tg(t), "Lam"), u => U32.add(1, j_lambda_count(kid(t, 0))), u => 0))

law j_lambda_code:
  for +book: List<&2, KDef>
  for +env: List<&2, KTerm>
  for +t: KTerm
  for +ty: KTerm
  for +at: U32
  String

@unsafe
def j_lambda_code(book, env, t, ty, at):
  kc(String, String.eq(tg(t), "Ann"), u => j_lambda_code(book, env, kid(t, 0), kid(t, 1), at), u => kc(String, String.eq(tg(t), "Lam"), u => j_lambda_bind(book, env, t, wnf(book, ty), at), u => "return " ++ j_expr(book, env, t, ty, True{}) ++ ";"))

law j_lambda_bind:
  for +book: List<&2, KDef>
  for +env: List<&2, KTerm>
  for +t: KTerm
  for +ty: KTerm
  for +at: U32
  String

@unsafe
def j_lambda_bind(book, env, t, ty, at):
  "const " ++ j_local(ix(t)) ++ "=" ++ kc(String, U32.is_eq(qt(ty), 0) && String.eq(tg(ty), "All"), u => "null", u => "a[" ++ U32.show(at) ++ "]") ++ ";" ++ j_lambda_code(book, Con{kt("Env", "", ix(t), 0, Con{kid(ty, 0), Nil{}}), env}, kid(t, 0), subst(kid(ty, 1), ix(ty), var(nm(t), ix(t))), U32.add(at, 1))

law j_apply:
  for +book: List<&2, KDef>
  for +env: List<&2, KTerm>
  for +t: KTerm
  for +tail: Bool
  for +fty: KTerm
  String

@unsafe
def j_apply(book, env, t, tail, fty):
  j_apply_spine(book, env, t, tail, fty, j_call_spine(t, Nil{}))

@unsafe
def j_apply_one(
  +book: List<&2, KDef>,
  +env: List<&2, KTerm>,
  +t: KTerm,
  +tail: Bool,
  +fty: KTerm,
) -> String:
  kc(String, tail, u => "jump(", u => "callOwned(") ++ j_expr(book, env, kid(t, 0), fty, False{}) ++ ",[" ++ kc(String, String.eq(tg(fty), "All") && U32.is_eq(qt(fty), 0), u => "null", u => j_expr(book, env, kid(t, 1), kid(fty, 0), False{})) ++ "])"

law j_call_spine:
  for +t: KTerm
  for +args: List<&2, KTerm>
  KTerm

@unsafe
def j_call_spine(t, args):
  kc(KTerm, String.eq(tg(t), "Ann"), u => j_call_spine(kid(t, 0), args), u => kc(KTerm, String.eq(tg(t), "App"), u => j_call_spine(kid(t, 0), Con{kid(t, 1), args}), u => kc(KTerm, String.eq(tg(t), "Ref"), u => kt("Call", nm(t), 0, 0, args), u => atom("Absent"))))

law j_apply_spine:
  for +book: List<&2, KDef>
  for +env: List<&2, KTerm>
  for +t: KTerm
  for +tail: Bool
  for +fty: KTerm
  for +spine: KTerm
  String

@unsafe
def j_apply_spine(book, env, t, tail, fty, spine):
  kc(String, j_primitive_call(book, spine), u => j_primitive_emit(book, env, spine), u => kc(String, j_choice_call(book, spine), u => j_choice_emit(book, env, spine, tail), u => j_apply_regular(book, env, t, tail, fty, spine)))

law j_apply_regular:
  for +book: List<&2, KDef>
  for +env: List<&2, KTerm>
  for +t: KTerm
  for +tail: Bool
  for +fty: KTerm
  for +spine: KTerm
  String

@unsafe
def j_apply_regular(book, env, t, tail, fty, spine):
  kc(String, String.eq(tg(spine), "Call") && U32.is_gt(terms_len(ks(spine)), 1) && U32.is_le(terms_len(ks(spine)), j_call_arity(lookup(book, nm(spine)))), u => kc(String, tail, u => "jump(", u => "callOwned(") ++ "get(G," ++ j_quote(nm(spine)) ++ "),[" ++ j_apply_args(book, env, ks(spine), dt(lookup(book, nm(spine)))) ++ "])", u => j_apply_one(book, env, t, tail, fty))

law j_call_arity:
  for +d: KDef
  U32

@unsafe
def j_call_arity(d):
  kc(U32, db(d) && j_intrinsic(dn(d)), u => da(d), u => j_lambda_count(dv(d)))

law j_apply_args:
  for +book: List<&2, KDef>
  for +env: List<&2, KTerm>
  for +args: List<&2, KTerm>
  for +ty: KTerm
  String

@unsafe
def j_apply_args(book, env, args, ty):
  j_apply_args_head(book, env, args, wnf(book, ty))

law j_apply_args_head:
  for +book: List<&2, KDef>
  for +env: List<&2, KTerm>
  for +args: List<&2, KTerm>
  for +ty: KTerm
  String

@unsafe
def j_apply_args_head(book, env, args, ty):
  match args:
    case Nil{}: ""
    case Con{h, rest}:
      kc(String, String.eq(tg(ty), "All") && U32.is_eq(qt(ty), 0), u => "null", u => j_expr(book, env, h, kid(ty, 0), False{})) ++ "," ++ j_apply_args(book, env, rest, j_app_type(ty, h))

law j_descriptor:
  for +book: List<&2, KDef>
  for +ty: KTerm
  for +fuel: U32
  String

@unsafe
def j_descriptor(book, ty, fuel):
  j_desc_kind(book, wnf(book, ty), fuel)

@unsafe
def j_desc_head(
  +book: List<&2, KDef>,
  +ty: KTerm,
  +fuel: U32,
) -> String:
  j_desc_head_on(book, ty, fuel, nm(ty))

law j_desc_head_on:
  for +book: List<&2, KDef>
  for +ty: KTerm
  for +fuel: U32
  for +key: String
  String

@unsafe
def j_desc_head_on(book, ty, fuel, key):
  kc(String, String.eq(key, "Char"), u => "[\"Char\"]", u => kc(String, String.eq(key, "F32"), u => "[\"F32\"]", u => kc(String, String.eq(key, "List"), u => "[\"List\"," ++ j_descriptor(book, kid(ty, 1), fuel) ++ "]", u => kc(String, String.eq(key, "Array"), u => "[\"Array\"," ++ j_descriptor(book, kid(ty, 0), fuel) ++ "]", u => kc(String, String.eq(key, "Sigma"), u => "[\"Tuple\"," ++ j_descriptor(book, kid(ty, 2), fuel) ++ "," ++ j_descriptor(book, kid(kid(ty, 3), 0), fuel) ++ "]", u => kc(String, String.eq(tg(ty), "Var"), u => "(typeof " ++ j_local(ix(ty)) ++ "===\"undefined\"?null:" ++ j_local(ix(ty)) ++ ")", u => kc(String, String.eq(tg(ty), "ADT"), u => "[\"Named\"," ++ j_quote(nm(ty)) ++ ",[" ++ j_desc_args(book, ks(ty), fuel) ++ "]]", u => "null")))))))

law j_intrinsic:
  for +name: String
  Bool

@unsafe
def j_intrinsic(name):
  String.contains("|U32.add|U32.sub|U32.and|U32.or|U32.xor|U32.is_eq|U32.is_ne|U32.is_lt|U32.is_le|U32.is_gt|U32.is_ge|U32.mul|U32.div|U32.mod|U32.inc|U32.shl|U32.shr|U32.shln|U32.shrn|U32.not|U32.is_zero|U32.cmp|U32.to_f32|U32.to_nat|U32.from_nat|F32.add|F32.sub|F32.mul|F32.div|F32.neg|F32.is_eq|F32.is_ne|F32.is_lt|F32.is_le|F32.is_gt|F32.is_ge|F32.sqrt|F32.exp|F32.log|F32.log2|F32.log10|F32.sin|F32.cos|F32.tan|F32.asin|F32.acos|F32.atan|F32.sinh|F32.cosh|F32.tanh|F32.floor|F32.ceil|F32.trunc|F32.abs|F32.pow|F32.atan2|F32.mod|F32.to_u32|F32.bits|F32.show|F32.read|Nat.add|Nat.sub|Nat.mul|Nat.double|Nat.cmp|Nat.is_lt|Nat.divmod|Array.new|Array.set|Array.get|Array.swap|Array.size|Array.clone|Array.atomic.add|Array.atomic.min|Array.atomic.max|Array.atomic.and|Array.atomic.or|Array.atomic.xor|Array.atomic.exch|Array.atomic.cas|Array.atomic.fadd|IO.pure|IO.bind|IO.try|IO.pass|IO.die|IO.args|IO.print|IO.write|IO.print_err|IO.get_env|IO.now|IO.sleep|IO.random_u32|IO.spawn|IO.fork|IO.join|String.append|String.length|String.eq|String.contains|String.starts_with|String.reverse|String.is_empty|Bool.or|Bool.xor|", "|" ++ name ++ "|")

@unsafe
def j_def(
  +book: List<&2, KDef>,
  +d: KDef,
) -> String:
  kc(String, String.eq(tg(dv(d)), "Foreign"), u => j_foreign_def(book, d), u => kc(String, String.eq(dk(d), "Def") && U32.is_eq(dx(d), 0) && Bool.not(String.eq(tg(dv(d)), "Absent")) && Bool.not(String.eq(tg(dv(d)), "Foreign")),
    u => kc(String, db(d) && j_intrinsic(dn(d)), u => "if(!Object.hasOwn(G," ++ j_quote(dn(d)) ++ "))", u => "") ++ j_l_def(book, d),
    u => ""))

@unsafe
def j_defs(
  +book: List<&2, KDef>,
  +defs: List<&2, KDef>,
) -> String:
  match defs:
    case Nil{}:
      ""
    case Con{d, rest}:
      j_def(book, d) ++ j_defs(book, rest)

@unsafe
def j_program(
  +book: List<&2, KDef>,
) -> String:
  j_program_selected(book, book)

law j_program_selected:
  for +book: List<&2, KDef>
  for +defs: List<&2, KDef>
  String

@unsafe
def j_program_selected(book, defs):
  j_program_context(book_context(book), defs)

law j_program_context:
  for +book: List<&2, KDef>
  for +defs: List<&2, KDef>
  String

@unsafe
def j_program_context(book, defs):
  j_ctor_metadata(defs) ++ j_schemas(book, defs) ++ j_defs(book, defs) ++ "\nawait runmain(" ++ j_descriptor(book, dt(lookup(book, "main")), 64) ++ "," ++ kc(String, j_io_type(book, dt(lookup(book, "main"))), u => "true", u => "false") ++ ");\n"

law j_let:
  for +book: List<&2, KDef>
  for +env: List<&2, KTerm>
  for +xs: List<&2, KTerm>
  for +ty: KTerm
  for +tail: Bool
  String

@unsafe
def j_let(book, env, xs, ty, tail):
  "((" ++ j_bindings(book, env, xs) ++ ")=>" ++ j_expr(book, j_context(book, env, xs), j_body(xs), ty, tail) ++ ")(" ++ j_let_values(book, env, xs) ++ ")"

law j_bindings:
  for +book: List<&2, KDef>
  for +env: List<&2, KTerm>
  for +xs: List<&2, KTerm>
  String

@unsafe
def j_bindings(book, env, xs):
  match xs:
    case Nil{}:
      ""
    case Con{h, Nil{}}:
      ""
    case Con{h, rest}:
      j_local(ix(h)) ++ "," ++ j_bindings(book, env, rest)

law j_context:
  for +book: List<&2, KDef>
  for +env: List<&2, KTerm>
  for +xs: List<&2, KTerm>
  List<&2, KTerm>

@unsafe
def j_context(book, env, xs):
  match xs:
    case Nil{}:
      env
    case Con{h, Nil{}}:
      env
    case Con{h, rest}:
      Con{kt("Env", "", ix(h), 0, Con{j_type(book, env, kid(h, 0)), Nil{}}), j_context(book, env, rest)}

law j_body:
  for +xs: List<&2, KTerm>
  KTerm

@unsafe
def j_body(xs):
  match xs:
    case Nil{}:
      atom("Absent")
    case Con{h, Nil{}}:
      h
    case Con{h, rest}:
      j_body(rest)
# Constructor telescopes specialize ADT parameters before entering match arms.
law j_find_ctor:
  for +book: List<&2, KDef>
  for +name: String
  KDef

@unsafe
def j_find_ctor(book, name):
  match book:
    case Nil{}:
      missing()
    case Con{d, rest}:
      j_found_ctor(lookup(dc(d), name), rest, name)

law j_found_ctor:
  for +found: KDef
  for +rest: List<&2, KDef>
  for +name: String
  KDef

@unsafe
def j_found_ctor(found, rest, name):
  kc(KDef, String.eq(dk(found), "Absent"), u => j_find_ctor(rest, name), u => found)

law j_specialize:
  for +book: List<&2, KDef>
  for +tel: KTerm
  for +args: List<&2, KTerm>
  KTerm

@unsafe
def j_specialize(book, tel, args):
  match args:
    case Nil{}:
      tel
    case Con{h, rest}:
      j_specialize(book, j_app_type(wnf(book, tel), h), rest)

law j_arm_type:
  for +book: List<&2, KDef>
  for +ty: KTerm
  for +name: String
  KTerm

@unsafe
def j_arm_type(book, ty, name):
  j_arm_tel(book, j_specialize(book, dt(j_find_ctor(book, name)), ks(wnf(book, kid(ty, 0)))), kid(ty, 1))

law j_arm_tel:
  for +book: List<&2, KDef>
  for +tel: KTerm
  for +ret: KTerm
  KTerm

@unsafe
def j_arm_tel(book, tel, ret):
  kc(KTerm, String.eq(tg(tel), "All"), u => all(qt(tel), nm(tel), ix(tel), kid(tel, 0), j_arm_tel(book, kid(tel, 1), ret)), u => ret)
# Readback schemas are finite graphs. Recursive ADTs refer to schema names;
# neither the compiler nor the runtime expands recursive types eagerly.
law j_schemas:
  for +book: List<&2, KDef>
  for +defs: List<&2, KDef>
  String

@unsafe
def j_schemas(book, defs):
  match defs:
    case Nil{}:
      ""
    case Con{d, rest}:
      kc(String, String.eq(dk(d), "ADT"), u => "showSchemas[" ++ j_quote(dn(d)) ++ "]=(p)=>[\"ADT\",{" ++ j_schema_ctors(book, dc(d), da(d)) ++ "}];\n", u => "") ++ j_schemas(book, rest)

law j_schema_ctors:
  for +book: List<&2, KDef>
  for +ctors: List<&2, KDef>
  for +params: U32
  String

@unsafe
def j_schema_ctors(book, ctors, params):
  match ctors:
    case Nil{}:
      ""
    case Con{d, rest}:
      j_quote(dn(d)) ++ ":(()=>{" ++ j_schema_params(book, dt(d), params, 0) ++ "})()," ++ j_schema_ctors(book, rest, params)

law j_schema_params:
  for +book: List<&2, KDef>
  for +ty: KTerm
  for +left: U32
  for +index: U32
  String

@unsafe
def j_schema_params(book, ty, left, index):
  kc(String, U32.is_eq(left, 0), u => "return [" ++ j_schema_fields(book, ty) ++ "];", u => "const " ++ j_local(ix(ty)) ++ "=p[" ++ U32.show(index) ++ "];" ++ j_schema_params(book, kid(ty, 1), U32.sub(left, 1), U32.add(index, 1)))

law j_schema_fields:
  for +book: List<&2, KDef>
  for +ty: KTerm
  String

@unsafe
def j_schema_fields(book, ty):
  kc(String, String.eq(tg(ty), "All"), u => kc(String, U32.is_eq(qt(ty), 0), u => "[\"Erased\"]", u => j_descriptor(book, kid(ty, 0), 64)) ++ "," ++ j_schema_fields(book, kid(ty, 1)), u => "")

law j_desc_args:
  for +book: List<&2, KDef>
  for +args: List<&2, KTerm>
  for +fuel: U32
  String

@unsafe
def j_desc_args(book, args, fuel):
  match args:
    case Nil{}:
      ""
    case Con{h, rest}:
      j_descriptor(book, h, fuel) ++ "," ++ j_desc_args(book, rest, fuel)
@unsafe
def j_ctor_args(
  +book: List<&2, KDef>,
  +env: List<&2, KTerm>,
  +args: List<&2, KTerm>,
  +tel: KTerm,
) -> String:
  match args:
    case Nil{}:
      ""
    case Con{h, rest}:
      kc(String, String.eq(tg(tel), "All") && U32.is_eq(qt(tel), 0), u => "null", u => j_expr(book, env, h, kid(tel, 0), False{})) ++ "," ++ j_ctor_args(book, env, rest, j_app_type(tel, h))

# Constructor fields in return position are evaluated by the application
# trampoline, retaining source order without growing the host call stack.
law j_constructor_mode:
  for +book: List<&2, KDef>
  for +env: List<&2, KTerm>
  for +t: KTerm
  for +ty: KTerm
  for +tail: Bool
  String

@unsafe
def j_constructor_mode(book, env, t, ty, tail):
  +literal = j_literal_typed(book, t, ty)
  kc(String, tail && String.eq(literal, ""), u => "build(" ++ j_quote(nm(t)) ++ ",[" ++ j_ctor_thunks(book, env, ks(t), j_specialize(book, dt(j_layout_ctor(book, wnf(book, ty), nm(t))), ks(wnf(book, ty)))) ++ "])", u => j_constructor_literal(book, env, t, ty, literal))

law j_ctor_thunks:
  for +book: List<&2, KDef>
  for +env: List<&2, KTerm>
  for +args: List<&2, KTerm>
  for +tel: KTerm
  String

@unsafe
def j_ctor_thunks(book, env, args, tel):
  match args:
    case Nil{}:
      ""
    case Con{h, rest}:
      "()=>" ++ kc(String, String.eq(tg(tel), "All") && U32.is_eq(qt(tel), 0), u => "null", u => j_expr(book, env, h, kid(tel, 0), True{})) ++ "," ++ j_ctor_thunks(book, env, rest, j_app_type(tel, h))

law j_constructor_literal:
  for +book: List<&2, KDef>
  for +env: List<&2, KTerm>
  for +t: KTerm
  for +ty: KTerm
  for +literal: String
  String

@unsafe
def j_constructor_literal(book, env, t, ty, literal):
  kc(String, String.eq(literal, ""), u => "ctor(" ++ j_quote(nm(t)) ++ ",[" ++ j_ctor_args(book, env, ks(t), j_specialize(book, dt(j_layout_ctor(book, wnf(book, ty), nm(t))), ks(wnf(book, ty)))) ++ "])", u => literal)

law j_io_type:
  for +book: List<&2, KDef>
  for +ty: KTerm
  Bool

@unsafe
def j_io_type(book, ty):
  kc(Bool, String.eq(dk(lookup(book, "IO")), "Def") && db(lookup(book, "IO")), u => j_io_spine(wnf(j_io_shadow(book), ty), 0), u => False{})

law j_io_shadow:
  for +book: List<&2, KDef>
  List<&2, KDef>

@unsafe
def j_io_shadow(book):
  j_io_shadow_def(book, lookup(book, "IO"))

law j_io_shadow_def:
  for +book: List<&2, KDef>
  for +d: KDef
  List<&2, KDef>

@unsafe
def j_io_shadow_def(book, d):
  book_put(book, KDef{dn(d), dk(d), da(d), dx(d), dt(d), atom("Absent"), dc(d), db(d), du(d)})

law j_io_spine:
  for +t: KTerm
  for +args: U32
  Bool

@unsafe
def j_io_spine(t, args):
  kc(Bool, String.eq(tg(t), "App"), u => j_io_spine(kid(t, 0), U32.add(args, 1)), u => String.eq(tg(t), "Ref") && String.eq(nm(t), "IO") && U32.is_eq(args, 1))

# Library output exposes the same primitive ABI as generated executables;
# callers may use G/call/list/ctor without invoking main.
@unsafe
def j_library(
  +book: List<&2, KDef>,
) -> String:
  j_library_selected(book, book)

law j_library_selected:
  for +book: List<&2, KDef>
  for +defs: List<&2, KDef>
  String

@unsafe
def j_library_selected(book, defs):
  j_library_context(book_context(book), defs)

law j_library_context:
  for +book: List<&2, KDef>
  for +defs: List<&2, KDef>
  String

@unsafe
def j_library_context(book, defs):
  j_ctor_metadata(defs) ++ j_schemas(book, defs) ++ j_defs(book, defs) ++ "\nexport {G,call,list,ctor};\nexport default Object.fromEntries(Object.keys(G).map(k=>[k,(...args)=>call(get(G,k),args)]));\n"

law j_desc_kind:
  for +book: List<&2, KDef>
  for +ty: KTerm
  for +fuel: U32
  String

@unsafe
def j_desc_kind(book, ty, fuel):
  kc(String, String.eq(tg(ty), "All"), u => "[\"Fun\"," ++ U32.show(qt(ty)) ++ "," ++ j_descriptor(book, kid(ty, 0), fuel) ++ "," ++ j_descriptor(book, kid(ty, 1), fuel) ++ "]", u => j_desc_head(book, ty, fuel))
# Roots and intrinsic stops for the shared dependency reachability pass.
@unsafe
def j_roots(
  +book: List<&2, KDef>,
  +library: Bool,
) -> List<&2, String>:
  kc(List<&2, String>, library, u => j_library_roots(book), u => ["main"])

law j_library_roots:
  for +book: List<&2, KDef>
  List<&2, String>

@unsafe
def j_library_roots(book):
  match book:
    case Nil{}:
      Nil{}
    case Con{d, rest}:
      kc(List<&2, String>, String.eq(dk(d), "Def") && U32.is_eq(dx(d), 0) && Bool.not(String.eq(tg(dv(d)), "Absent")) && (Bool.not(db(d)) || String.eq(tg(dv(d)), "Foreign")), u => Con{dn(d), j_library_roots(rest)}, u => j_library_roots(rest))

@unsafe
def j_stops(
  +book: List<&2, KDef>,
) -> List<&2, String>:
  match book:
    case Nil{}:
      Nil{}
    case Con{d, rest}:
      kc(List<&2, String>, db(d) && j_intrinsic(dn(d)), u => Con{dn(d), j_stops(rest)}, u => j_stops(rest))
# A checked residual datatype with one remaining constructor needs projection,
# not another tag test. This also preserves the foreign JS lane's trusted values.
law j_match:
  for +book: List<&2, KDef>
  for +env: List<&2, KTerm>
  for +t: KTerm
  for +ty: KTerm
  String

@unsafe
def j_match(book, env, t, ty):
  kc(String, U32.is_eq(j_constructor_count(book, wnf(book, kid(ty, 0))), 1),
    u => "matcher1(" ++ j_quote(nm(t)) ++ ",()=>" ++ j_expr(book, env, kid(t, 0), j_arm_type(book, ty, nm(t)), False{}) ++ ")",
    u => "matcher(" ++ j_quote(nm(t)) ++ ",()=>" ++ j_expr(book, env, kid(t, 0), j_arm_type(book, ty, nm(t)), False{}) ++ ",()=>" ++ j_expr(book, env, kid(t, 1), ty, False{}) ++ ")")

law j_constructor_count:
  for +book: List<&2, KDef>
  for +ty: KTerm
  U32

@unsafe
def j_constructor_count(book, ty):
  j_count_constructors(dc(lookup(book, nm(ty))), rm(ty))

law j_count_constructors:
  for +ctors: List<&2, KDef>
  for +removed: List<&2, String>
  U32

@unsafe
def j_count_constructors(ctors, removed):
  match ctors:
    case Nil{}:
      0
    case Con{d, rest}:
      U32.add(kc(U32, has_name(removed, dn(d)), u => 0, u => 1), j_count_constructors(rest, removed))

# Parallel RHSs are evaluated outside the scope introducing their binders.
law j_let_values:
  for +book: List<&2, KDef>
  for +env: List<&2, KTerm>
  for +xs: List<&2, KTerm>
  String

@unsafe
def j_let_values(book, env, xs):
  match xs:
    case Nil{}: ""
    case Con{h, Nil{}}: ""
    case Con{h, rest}:
      kc(String, U32.is_eq(qt(h), 0), u => "null", u => j_expr(book, env, kid(h, 0), atom("Absent"), False{})) ++ "," ++ j_let_values(book, env, rest)

# Deep closures use flat factories with explicit lexical captures.
@unsafe
def j_l_name(t):
  j_l_names(rm(t))

@unsafe
def j_l_names(names):
  match names:
    case Nil{}: ""
    case Con{h, rest}: kc(String, String.starts_with(h, "$js."), u => h, u => "")

@unsafe
def j_l_capture(env, seen):
  match env:
    case Nil{}: ""
    case Con{h, rest}:
      kc(String, has_name(seen, j_local(ix(h))), u => j_l_capture(rest, seen), u => j_local(ix(h)) ++ "," ++ j_l_capture(rest, Con{j_local(ix(h)), seen}))

@unsafe
def j_l_deep(
  +t: KTerm,
  +depth: U32,
) -> Bool:
  kc(Bool, String.eq(tg(t), "Ann"), u => j_l_deep(kid(t, 0), depth), u =>
  kc(Bool, String.eq(tg(t), "Var") || String.eq(tg(t), "Ref"), u => False{}, u =>
  kc(Bool, String.eq(tg(t), "Lam") || String.eq(tg(t), "Mat"), u => kc(Bool, U32.is_ge(depth, 32), u => True{}, u => j_l_deeps(ks(t), U32.inc(depth))), u => j_l_deeps(ks(t), depth))))

@unsafe
def j_l_deeps(ts, depth):
  match ts:
    case Nil{}: False{}
    case Con{h, rest}: kc(Bool, j_l_deep(h, depth), u => True{}, u => j_l_deeps(rest, depth))

@unsafe
def j_l_mark(
  +t: KTerm,
  +path: String,
  +depth: U32,
) -> KTerm:
  kc(KTerm, String.eq(tg(t), "Ann"), u => k_with_children(t, [j_l_mark(kid(t, 0), path, depth), kid(t, 1)]), u =>
  kc(KTerm, String.eq(tg(t), "Var") || String.eq(tg(t), "Ref"), u => t, u =>
  kc(KTerm, String.eq(tg(t), "Lam") || String.eq(tg(t), "Mat"), u =>
    kc(KTerm, U32.is_ge(depth, 32), u => k_rebuild(t, nm(t), ix(t), qt(t), j_l_marks(ks(t), path, 0, 0), ["$js." ++ path], kb(t), ke(t)), u => k_with_children(t, j_l_marks(ks(t), path, U32.inc(depth), 0))), u =>
    k_with_children(t, j_l_marks(ks(t), path, depth, 0)))))

@unsafe
def j_l_marks(ts, path, depth, at):
  match ts:
    case Nil{}: Nil{}
    case Con{h, rest}: Con{j_l_mark(h, path ++ "_" ++ U32.show(at), depth), j_l_marks(rest, path, depth, U32.inc(at))}

@unsafe
def j_l_def(book, d):
  +worker = j_nat_loop_worker(book, d)
  kc(String, String.eq(worker, ""), u => j_tree_global(book, d), u => "G[" ++ j_quote(dn(d)) ++ "]=" ++ worker ++ ";\n")

@unsafe
def j_l_definition(book, d, t):
  "{const F=Object.create(null);\n" ++ j_l_walk(book, Nil{}, t, dt(d)) ++ j_l_global(book, d, t) ++ "}\n"

@unsafe
def j_l_walk(book, env, t, ty):
  kc(String, String.eq(tg(t), "Ann"), u => j_l_walk(book, env, kid(t, 0), kid(t, 1)), u =>
  kc(String, String.eq(j_l_name(t), ""), u => "", u => "F[" ++ j_quote(j_l_name(t)) ++ "]=function(" ++ j_l_capture(env, Nil{}) ++ "){return " ++ j_expr_on(book, env, t, ty, False{}, tg(t)) ++ ";};\n") ++ j_l_children(book, env, t, ty))

@unsafe
def j_l_children(book, env, t, ty):
  kc(String, String.eq(tg(t), "Lam"), u => j_l_lam(book, env, t, wnf(book, ty)), u =>
  kc(String, String.eq(tg(t), "Mat"), u => j_l_mat(book, env, t, wnf(book, ty)), u =>
  kc(String, String.eq(tg(t), "App"), u => j_l_app(book, env, t, wnf(book, j_type(book, env, kid(t, 0)))), u =>
  kc(String, String.eq(tg(t), "Let"), u => j_l_bindings(book, env, ks(t)) ++ j_l_walk(book, j_context(book, env, ks(t)), j_body(ks(t)), ty), u =>
  kc(String, String.eq(tg(t), "Ctr"), u => kc(String, String.eq(j_literal_typed(book, t, ty), ""), u => j_l_fields(book, env, ks(t), j_specialize(book, dt(j_layout_ctor(book, wnf(book, ty), nm(t))), ks(wnf(book, ty)))), u => ""), u =>
  kc(String, String.eq(tg(t), "Rwt"), u => j_l_walk(book, env, kid(t, 2), ty), u => ""))))))

@unsafe
def j_l_lam(book, env, t, ty):
  j_l_walk(book, Con{kt("Env", "", ix(t), 0, [kid(ty, 0)]), env}, kid(t, 0), subst(kid(ty, 1), ix(ty), var(nm(t), ix(t))))

@unsafe
def j_l_mat(book, env, t, ty):
  j_l_walk(book, env, kid(t, 0), j_arm_type(book, ty, nm(t))) ++ kc(String, U32.is_eq(j_constructor_count(book, wnf(book, kid(ty, 0))), 1), u => "", u => j_l_walk(book, env, kid(t, 1), ty))

@unsafe
def j_l_app(book, env, t, ty):
  j_l_walk(book, env, kid(t, 0), ty) ++ kc(String, String.eq(tg(ty), "All") && U32.is_eq(qt(ty), 0), u => "", u => j_l_walk(book, env, kid(t, 1), kid(ty, 0)))

@unsafe
def j_l_fields(book, env, ts, ty):
  match ts:
    case Nil{}: ""
    case Con{h, rest}: kc(String, String.eq(tg(ty), "All") && U32.is_eq(qt(ty), 0), u => "", u => j_l_walk(book, env, h, kid(ty, 0))) ++ j_l_fields(book, env, rest, j_app_type(ty, h))

@unsafe
def j_l_bindings(book, env, ts):
  match ts:
    case Nil{}: ""
    case Con{h, Nil{}}: ""
    case Con{h, rest}: kc(String, U32.is_eq(qt(h), 0), u => "", u => j_l_walk(book, env, kid(h, 0), j_type(book, env, kid(h, 0)))) ++ j_l_bindings(book, env, rest)

# Leading lambdas and matchers are pure closure initializers; their bodies stay delayed.
law j_l_global:
  for +book: List<&2, KDef>
  for +d: KDef
  for +t: KTerm
  String

@unsafe
def j_l_global(book, d, t):
  j_l_global_worker(book, d, t, j_projection_worker(book, t, dt(d)))

@unsafe
def j_region_native_emit(+book: List<&2,KDef>, +env: List<&2,KTerm>, +t: KTerm) -> String:
  +args = j_apply_args(book, env, ks(t), dt(lookup(book, nm(t))))
  kc(String, String.eq(nm(t), "Array.new"), u => "((_t,d,v)=>arrayfill(v,d,'^'))(" ++ args ++ ")", u =>
    kc(String, String.eq(nm(t), "Array.get"), u => "((_t,a,i)=>arrayget(a,i))(" ++ args ++ ")", u => "((_t,a,i,v)=>arrayset(a,i,v))(" ++ args ++ ")"))

# The plan retains the proved input type. Immutable private field vectors cannot
# escape; argument evaluation snapshots every field before the arm's effects.
@unsafe
def j_region_field_reads(+base: String, +at: U32, +total: U32) -> String:
  kc(String, U32.is_eq(at, total), u => "", u => base ++ "[" ++ U32.show(at) ++ "]" ++
    kc(String, U32.is_eq(U32.inc(at), total), u => "", u => "," ++ j_region_field_reads(base, U32.inc(at), total)))
