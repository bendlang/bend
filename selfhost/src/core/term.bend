import Base

@unsafe
def kc(
  -A: Type,
  +b: Bool,
  yes: Unit -> A,
  no: Unit -> A,
) -> A:
  match b:
    case True{}:
      yes(Unit{})
    case False{}:
      no(Unit{})

# First-order trusted core. Binder identifiers are globally unique.
# Quantities: 0 erased, 1 affine, 2 unrestricted. No function-valued fields.
type KTerm is Data:
  KTerm{+tag: String, +name: String, +id: U32, +quant: U32, +kids: List<&2, KTerm>, +removed: List<&2, String>, +originBegin: U32, +originEnd: U32}
  KLambda{+name: String, +id: U32, +quant: U32, +kids: List<&2,KTerm>, +removed: List<&2,String>, +originBegin: U32, +originEnd: U32, +quantityPresent: Bool}
  KLiteral{+kind: String, +number: U32, +text: String, +originBegin: U32, +originEnd: U32}

type KDef is Data:
  KDef{+name: String, +kind: String, +arity: U32, +templates: U32, +typ: KTerm, +value: KTerm, +ctors: List<&2, KDef>, +native: Bool, +unsafe: Bool}

@unsafe
def kt(
  +tag: String,
  +name: String,
  +id: U32,
  +quant: U32,
  +kids: List<&2, KTerm>,
) -> KTerm:
  KTerm{tag, name, id, quant, kids, Nil{}, 0, 0}

@unsafe
def atom(
  +tag: String,
) -> KTerm:
  kt(tag, "", 0, 0, Nil{})

@unsafe
def tg(
  +t: KTerm,
) -> String:
  match t:
    case KTerm{tag, name, id, quant, kids, removed, originBegin, originEnd}:
      tag
    case KLambda{name, id, quant, kids, removed, begin, end, present}:
      "Lam"
    case KLiteral{kind, number, text, literalBegin, literalEnd}:
      "Lit"

@unsafe
def nm(
  +t: KTerm,
) -> String:
  match t:
    case KTerm{tag, name, id, quant, kids, removed, originBegin, originEnd}:
      name
    case KLambda{name, id, quant, kids, removed, begin, end, present}:
      name
    case KLiteral{kind, number, text, literalBegin, literalEnd}:
      kind

@unsafe
def ix(
  +t: KTerm,
) -> U32:
  match t:
    case KTerm{tag, name, id, quant, kids, removed, originBegin, originEnd}:
      id
    case KLambda{name, id, quant, kids, removed, begin, end, present}:
      id
    case KLiteral{kind, number, text, literalBegin, literalEnd}:
      0

@unsafe
def qt(
  +t: KTerm,
) -> U32:
  match t:
    case KTerm{tag, name, id, quant, kids, removed, originBegin, originEnd}:
      quant
    case KLambda{name, id, quant, kids, removed, begin, end, present}:
      quant
    case KLiteral{kind, number, text, literalBegin, literalEnd}:
      0

@unsafe
def ks(
  +t: KTerm,
) -> List<&2, KTerm>:
  match t:
    case KTerm{tag, name, id, quant, kids, removed, originBegin, originEnd}:
      kids
    case KLambda{name, id, quant, kids, removed, begin, end, present}:
      kids
    case KLiteral{kind, number, text, literalBegin, literalEnd}:
      Nil{}

@unsafe
def rm(
  +t: KTerm,
) -> List<&2, String>:
  match t:
    case KTerm{tag, name, id, quant, kids, removed, originBegin, originEnd}:
      removed
    case KLambda{name, id, quant, kids, removed, begin, end, present}:
      removed
    case KLiteral{kind, number, text, literalBegin, literalEnd}:
      Nil{}

@unsafe
def terms_at(
  +ts: List<&2, KTerm>,
  +n: U32,
) -> KTerm:
  match ts:
    case Nil{}:
      atom("Absent")
    case Con{h, t}:
      kc(KTerm, U32.is_eq(n, 0), u => h, u => terms_at(t, U32.sub(n, 1)))

@unsafe
def kid(
  +t: KTerm,
  +n: U32,
) -> KTerm:
  terms_at(ks(t), n)

@unsafe
def var(
  +name: String,
  +id: U32,
) -> KTerm:
  kt("Var", name, id, 0, Nil{})

@unsafe
def ref(
  +name: String,
) -> KTerm:
  kt("Ref", name, 0, 0, Nil{})

@unsafe
def qua(
  +q: U32,
) -> KTerm:
  kt("Qua", "", 0, q, Nil{})

@unsafe
def typ(
  +q: U32,
) -> KTerm:
  kt("Typ", "", 0, 0, Con{qua(q), Nil{}})

@unsafe
def app(
  +f: KTerm,
  +x: KTerm,
) -> KTerm:
  kt("App", "", 0, 0, Con{f, Con{x, Nil{}}})

@unsafe
def all(
  +q: U32,
  +name: String,
  +id: U32,
  +a: KTerm,
  +b: KTerm,
) -> KTerm:
  kt("All", name, id, q, Con{a, Con{b, Nil{}}})

@unsafe
def dn(
  +d: KDef,
) -> String:
  match d:
    case KDef{name, kind, arity, templates, typ, value, ctors, native, unsafe}:
      name

@unsafe
def dk(
  +d: KDef,
) -> String:
  match d:
    case KDef{name, kind, arity, templates, typ, value, ctors, native, unsafe}:
      kind

@unsafe
def da(
  +d: KDef,
) -> U32:
  match d:
    case KDef{name, kind, arity, templates, typ, value, ctors, native, unsafe}:
      arity

@unsafe
def dx(
  +d: KDef,
) -> U32:
  match d:
    case KDef{name, kind, arity, templates, typ, value, ctors, native, unsafe}:
      templates

@unsafe
def dt(
  +d: KDef,
) -> KTerm:
  match d:
    case KDef{name, kind, arity, templates, typ, value, ctors, native, unsafe}:
      typ

@unsafe
def dv(
  +d: KDef,
) -> KTerm:
  match d:
    case KDef{name, kind, arity, templates, typ, value, ctors, native, unsafe}:
      value

@unsafe
def dc(
  +d: KDef,
) -> List<&2, KDef>:
  match d:
    case KDef{name, kind, arity, templates, typ, value, ctors, native, unsafe}:
      ctors

@unsafe
def db(
  +d: KDef,
) -> Bool:
  match d:
    case KDef{name, kind, arity, templates, typ, value, ctors, native, unsafe}:
      native

@unsafe
def du(
  +d: KDef,
) -> Bool:
  match d:
    case KDef{name, kind, arity, templates, typ, value, ctors, native, unsafe}:
      unsafe

@unsafe
def missing() -> KDef:
  KDef{"", "Absent", 0, 0, atom("Absent"), atom("Absent"), Nil{}, False{}, False{}}

@unsafe
def lookup(
  +book: List<&2, KDef>,
  +name: String,
) -> KDef:
  match book:
    case Nil{}:
      missing()
    case Con{d, rest}:
      lookup_cached(d, rest, name, String.eq(dk(d), "BookCache"))

@unsafe
def lookup_cached(
  +d: KDef,
  +rest: List<&2, KDef>,
  +name: String,
  +cached: Bool,
) -> KDef:
  match cached:
    case True{}: index_lookup(d, name)
    case False{}: lookup_named(d, rest, name, String.eq(dn(d), name))

@unsafe
def lookup_named(
  +d: KDef,
  +rest: List<&2, KDef>,
  +name: String,
  +same: Bool,
) -> KDef:
  match same:
    case True{}: d
    case False{}: lookup(rest, name)

@unsafe
def terms_len(
  +ts: List<&2, KTerm>,
) -> U32:
  match ts:
    case Nil{}:
      0
    case Con{h, t}:
      U32.add(1, terms_len(t))

@unsafe
def has_name(
  +ns: List<&2, String>,
  +name: String,
) -> Bool:
  match ns:
    case Nil{}:
      False{}
    case Con{h, t}:
      has_name_next(t, name, String.eq(h, name))

@unsafe
def has_name_next(+rest: List<&2,String>, +name: String, +same: Bool) -> Bool:
  match same:
    case True{}: True{}
    case False{}: has_name(rest, name)

law subst_terms:
  for +ts: List<&2, KTerm>
  for +id: U32
  for +v: KTerm
  List<&2, KTerm>

law core_rebuild:
  for +t: KTerm
  KTerm

law core_apply:
  for +f: KTerm
  for +x: KTerm
  KTerm

law subst_node:
  for +t: KTerm
  for +id: U32
  for +v: KTerm
  KTerm

@unsafe
def subst(
  +t: KTerm,
  +id: U32,
  +v: KTerm,
) -> KTerm:
  kc(KTerm, String.eq(tg(t), "Var"), u => kc(KTerm, U32.is_eq(ix(t), id), u => v, u => t), u => subst_node(t, id, v))

@unsafe
def subst_node(t, id0, v):
  match t:
    case KTerm{tag, name, n, q, kids, removed, originBegin, originEnd}:
      core_rebuild(KTerm{tag, name, n, q, subst_terms(kids, id0, v), removed, originBegin, originEnd})
    case KLambda{name, id, quant, kids, removed, begin, end, present}:
      core_rebuild(KLambda{name, id, quant, subst_terms(kids, id0, v), removed, begin, end, present})
    case KLiteral{kind, number, text, literalBegin, literalEnd}:
      t

@unsafe
def subst_terms(ts, id, v):
  match ts:
    case Nil{}:
      Nil{}
    case Con{h, t}:
      Con{subst(h, id, v), subst_terms(t, id, v)}


@unsafe
def core_force(
  +t: KTerm,
) -> KTerm:
  kc(KTerm, String.eq(tg(t), "Ann"), u => core_force(kid(t, 0)),
    u => kc(KTerm, String.eq(tg(t), "Var") && U32.is_gt(terms_len(ks(t)), 0), u => core_force(kid(t, 0)), u => t))

@unsafe
def core_rebuild(t):
  kc(KTerm, String.eq(tg(t), "App"), u => core_apply_span(kid(t, 0), kid(t, 1), kb(t), ke(t)), u => t)

@unsafe
def core_apply(f, x):
  core_apply_span(f, x, 0, 0)

@unsafe
def core_apply_span(+f: KTerm, +x: KTerm, +begin: U32, +end: U32) -> KTerm:
  kc(KTerm, String.eq(tg(f), "Lam"), u => subst(kid(f, 0), ix(f), x), u => kt_span("App", "", 0, 0, [f, x], begin, end))

@unsafe
def core_beta(
  +t: KTerm,
) -> KTerm:
  kc(KTerm, String.eq(tg(t), "App"), u => core_apply_span(core_beta(kid(t, 0)), kid(t, 1), kb(t), ke(t)), u => t)

# Scan in substitution order: Var test, children, then App rebuilding.
# A false fact returns to ordinary substitution, preserving its work and errors.
# A canonical App also survives substitution unchanged if both children do and
# its unchanged function is not Lam. Every metadata/arity check is necessary
# because core_rebuild canonicalizes App nodes even without beta reduction.
law core_subst_stable_terms:
  for +ts: List<&2, KTerm>
  Bool

law core_subst_stable_app:
  for +kids: List<&2, KTerm>
  for +removed: List<&2, String>
  Bool

@unsafe
def core_subst_stable(
  +t: KTerm,
) -> Bool:
  match t:
    case KTerm{tag, name, id, quant, kids, removed, originBegin, originEnd}:
      kc(Bool, String.eq(tag, "Var"), u => False{},
        u => kc(Bool, core_subst_stable_terms(kids),
          u => kc(Bool, String.eq(tag, "App"),
            u => kc(Bool, String.eq(name, "") && U32.is_eq(id, 0) && U32.is_eq(quant, 0), u => core_subst_stable_app(kids, removed), u => False{}),
            u => True{}),
          u => False{}))
    case KLambda{name, id, quant, kids, removed, begin, end, present}:
      core_subst_stable_terms(kids)
    case KLiteral{kind, number, text, literalBegin, literalEnd}:
      True{}

@unsafe
def core_subst_stable_terms(ts):
  match ts:
    case Nil{}: True{}
    case Con{h, rest}:
      kc(Bool, core_subst_stable(h), u => core_subst_stable_terms(rest), u => False{})

law core_subst_stable_app_kids:
  for +kids: List<&2, KTerm>
  Bool

law core_subst_stable_app_tail:
  for +f: KTerm
  for +tail: List<&2, KTerm>
  Bool

law core_subst_stable_app_last:
  for +f: KTerm
  for +x: KTerm
  for +rest: List<&2, KTerm>
  Bool

@unsafe
def core_subst_stable_app(kids, removed):
  match removed:
    case Con{h, rest}: False{}
    case Nil{}: core_subst_stable_app_kids(kids)

@unsafe
def core_subst_stable_app_kids(kids):
  match kids:
    case Nil{}: False{}
    case Con{f, tail}: core_subst_stable_app_tail(f, tail)

@unsafe
def core_subst_stable_app_tail(f, tail):
  match tail:
    case Nil{}: False{}
    case Con{x, rest}: core_subst_stable_app_last(f, x, rest)

@unsafe
def core_subst_stable_app_last(f, x, rest):
  match rest:
    case Con{h, tail}: False{}
    case Nil{}:
      Bool.not(String.eq(tg(f), "Lam"))

@unsafe
def norm_join(
  +a: List<&2, KTerm>,
  +b: List<&2, KTerm>,
) -> List<&2, KTerm>:
  match a:
    case Nil{}:
      b
    case Con{h, t}:
      Con{h, norm_join(t, b)}

law norm_defs_join:
  for +a: List<&2, KDef>
  for +b: List<&2, KDef>
  List<&2, KDef>

@unsafe
def norm_defs_join(a, b):
  match a:
    case Nil{}:
      b
    case Con{h, rest}:
      Con{h, norm_defs_join(rest, b)}


# Numeric and string values retain source literal identity until demanded.
@unsafe
def core_nat(+t: KTerm) -> Bool:
  core_literal(t) && String.eq(nm(t), "Nat")

@unsafe
def core_nat_make(+n: U32) -> KTerm:
  kl_make("Nat", n, "")

@unsafe
def core_literal_type(+book: List<&2,KDef>, +t: KTerm, +ty: KTerm) -> Bool:
  String.eq(tg(ty), "ADT") && String.eq(nm(ty), nm(t)) && List.is_empty(&2, String, rm(ty)) && db(lookup(book, nm(t)))

@unsafe
def core_literal_word(+n: U32, +bits: U32, +begin: U32, +end: U32) -> KTerm:
  kc(KTerm, U32.is_eq(bits, 0), u => kt_span("Ctr", "WNil", 0, 1, Nil{}, begin, end),
    u => kt_span("Ctr", "WCon", 0, 1, [kt_span("Ctr", kc(String, U32.is_eq(U32.and(n, 1), 0), u => "False", u => "True"), 0, 1, Nil{}, begin, end), core_literal_word(U32.shrn(n, 1n), U32.sub(bits, 1), begin, end)], begin, end))

@unsafe
def core_literal_step(+t: KTerm) -> KTerm:
  kc(KTerm, String.eq(nm(t), "Nat"),
    u => kc(KTerm, U32.is_eq(kl_number(t), 0), u => kt_span("Ctr", "Zero", 0, 1, Nil{}, kb(t), ke(t)), u => kt_span("Ctr", "Succ", 0, 1, [KLiteral{"Nat", U32.sub(kl_number(t), 1), "", kb(t), ke(t)}], kb(t), ke(t))),
    u => kc(KTerm, String.eq(nm(t), "String"), u => core_literal_string(kl_text(t), kb(t), ke(t)),
      u => kt_span("Ctr", nm(t), 0, 1, [core_literal_word(kl_number(t), 32, kb(t), ke(t))], kb(t), ke(t))))

@unsafe
def core_literal_string(+s: String, +begin: U32, +end: U32) -> KTerm:
  match s:
    case SNil{}: kt_span("Ctr", "SNil", 0, 1, Nil{}, begin, end)
    case SCon{c, rest}: kt_span("Ctr", "SCon", 0, 1, [kt_span("Ctr", "Chr", 0, 1, [KLiteral{"U32", Char.to_u32(c), "", begin, end}], begin, end), KLiteral{"String", 0, rest, begin, end}], begin, end)

@unsafe
def core_literal_same(+a: KTerm, +b: KTerm) -> Bool:
  String.eq(nm(a), nm(b)) && U32.is_eq(kl_number(a), kl_number(b)) && String.eq(kl_text(a), kl_text(b))

@unsafe
def compiler_term_abi() -> U32:
  1

# Source ranges are non-semantic metadata. Zero/zero is absent; positive
# inclusive-start/exclusive-end coordinates belong to one source interval.
@unsafe
def kb(+t: KTerm) -> U32:
  match t:
    case KTerm{tag, name, id, quant, kids, removed, originBegin, originEnd}:
      originBegin
    case KLambda{name, id, quant, kids, removed, begin, end, present}:
      begin
    case KLiteral{kind, number, text, literalBegin, literalEnd}:
      literalBegin

@unsafe
def ke(+t: KTerm) -> U32:
  match t:
    case KTerm{tag, name, id, quant, kids, removed, originBegin, originEnd}:
      originEnd
    case KLambda{name, id, quant, kids, removed, begin, end, present}:
      end
    case KLiteral{kind, number, text, literalBegin, literalEnd}:
      literalEnd

@unsafe
def compiler_span_abi() -> U32:
  3

# Replace only semantic children; every other immutable field is preserved.
@unsafe
def k_with_children(+t: KTerm, +newKids: List<&2,KTerm>) -> KTerm:
  match t:
    case KTerm{tag, name, id, quant, oldKids, removed, originBegin, originEnd}:
      KTerm{tag, name, id, quant, newKids, removed, originBegin, originEnd}

# Explicit replacement does not guess or inherit an occurrence.
    case KLambda{name, id, quant, kids, removed, begin, end, present}:
      KLambda{name, id, quant, newKids, removed, begin, end, present}
    case KLiteral{kind, number, text, literalBegin, literalEnd}:
      t

@unsafe
def k_with_span(+t: KTerm, +newBegin: U32, +newEnd: U32) -> KTerm:
  match t:
    case KTerm{tag, name, id, quant, kids, removed, oldBegin, oldEnd}:
      KTerm{tag, name, id, quant, kids, removed, newBegin, newEnd}
    case KLambda{name, id, quant, kids, removed, begin, end, present}:
      KLambda{name, id, quant, kids, removed, newBegin, newEnd, present}
    case KLiteral{kind, number, text, literalBegin, literalEnd}:
      KLiteral{kind, number, text, newBegin, newEnd}

@unsafe
def kt_span(+tag: String, +name: String, +id: U32, +quant: U32,
  +kids: List<&2,KTerm>, +begin: U32, +end: U32) -> KTerm:
  KTerm{tag, name, id, quant, kids, Nil{}, begin, end}

# Interpreted literal leaves are closed; payload is never a binder or quantity.
@unsafe
def core_literal(+t: KTerm) -> Bool:
  match t:
    case KTerm{tag, name, id, quant, kids, removed, begin, end}: False{}
    case KLambda{name, id, quant, kids, removed, begin, end, present}:
      False{}
    case KLiteral{kind, number, text, begin, end}: True{}

@unsafe
def kl_number(+t: KTerm) -> U32:
  match t:
    case KTerm{tag, name, id, quant, kids, removed, begin, end}: 0
    case KLambda{name, id, quant, kids, removed, begin, end, present}:
      0
    case KLiteral{kind, number, text, begin, end}: number

@unsafe
def kl_text(+t: KTerm) -> String:
  match t:
    case KTerm{tag, name, id, quant, kids, removed, begin, end}: ""
    case KLambda{name, id, quant, kids, removed, begin, end, present}:
      ""
    case KLiteral{kind, number, text, begin, end}: text

@unsafe
def kl_make(+kind: String, +number: U32, +text: String) -> KTerm:
  KLiteral{kind, number, text, 0, 0}

# Quantity presence is explicit syntax metadata on Lambda only. Ordinary term
# allocation remains unchanged; legacy KTerm/Lam inputs supplied a quantity.
@unsafe
def k_lam(+name: String, +id: U32, +quant: U32, +kids: List<&2,KTerm>, +begin: U32, +end: U32, +present: Bool) -> KTerm:
  KLambda{name, id, quant, kids, Nil{}, begin, end, present}

@unsafe
def k_quantity_present(+t: KTerm) -> Bool:
  match t:
    case KTerm{tag, name, id, quant, kids, removed, begin, end}: String.eq(tag, "Lam")
    case KLambda{name, id, quant, kids, removed, begin, end, present}: present
    case KLiteral{kind, number, text, begin, end}: False{}

# Field-changing structural rebuilds retain the input variant and syntax fact.
@unsafe
def k_rebuild(+t: KTerm, +name: String, +id: U32, +quant: U32, +kids: List<&2,KTerm>, +removed: List<&2,String>, +begin: U32, +end: U32) -> KTerm:
  match t:
    case KTerm{tag, oldName, oldId, oldQuant, oldKids, oldRemoved, oldBegin, oldEnd}:
      KTerm{tag, name, id, quant, kids, removed, begin, end}
    case KLambda{oldName, oldId, oldQuant, oldKids, oldRemoved, oldBegin, oldEnd, present}:
      KLambda{name, id, quant, kids, removed, begin, end, present}
    case KLiteral{kind, number, text, oldBegin, oldEnd}: t

# Strong normalization, unlike alpha-renaming, omits the optional syntax q.
@unsafe
def k_snf_children(+t: KTerm, +kids: List<&2,KTerm>) -> KTerm:
  match t:
    case KTerm{tag, name, id, quant, oldKids, removed, begin, end}:
      kc(KTerm, String.eq(tag, "Lam"), u => KLambda{name, id, quant, kids, removed, begin, end, False{}}, u => KTerm{tag, name, id, quant, kids, removed, begin, end})
    case KLambda{name, id, quant, oldKids, removed, begin, end, present}:
      KLambda{name, id, quant, kids, removed, begin, end, False{}}
    case KLiteral{kind, number, text, begin, end}: t

# Scope flattening rebuilds a binder via a temporary pattern variable. Restore
# only its optional quantity syntax after that existing semantic operation.
@unsafe
def k_lambda_presence(+t: KTerm, +present: Bool) -> KTerm:
  match t:
    case KTerm{tag, name, id, quant, kids, removed, begin, end}:
      kc(KTerm, String.eq(tag, "Lam"), u => KLambda{name, id, quant, kids, removed, begin, end, present}, u => t)
    case KLambda{name, id, quant, kids, removed, begin, end, oldPresent}:
      KLambda{name, id, quant, kids, removed, begin, end, present}
    case KLiteral{kind, number, text, begin, end}: t
