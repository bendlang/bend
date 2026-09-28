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
  KTerm{+tag: String, +name: String, +id: U32, +quant: U32, +kids: List<&2, KTerm>, +removed: List<&2, String>}

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
  KTerm{tag, name, id, quant, kids, Nil{}}

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
    case KTerm{tag, name, id, quant, kids, removed}:
      tag

@unsafe
def nm(
  +t: KTerm,
) -> String:
  match t:
    case KTerm{tag, name, id, quant, kids, removed}:
      name

@unsafe
def ix(
  +t: KTerm,
) -> U32:
  match t:
    case KTerm{tag, name, id, quant, kids, removed}:
      id

@unsafe
def qt(
  +t: KTerm,
) -> U32:
  match t:
    case KTerm{tag, name, id, quant, kids, removed}:
      quant

@unsafe
def ks(
  +t: KTerm,
) -> List<&2, KTerm>:
  match t:
    case KTerm{tag, name, id, quant, kids, removed}:
      kids

@unsafe
def rm(
  +t: KTerm,
) -> List<&2, String>:
  match t:
    case KTerm{tag, name, id, quant, kids, removed}:
      removed

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
      kc(KDef, String.eq(dk(d), "BookCache"), u => index_lookup(d, name), u => kc(KDef, String.eq(dn(d), name), u => d, u => lookup(rest, name)))

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
      kc(Bool, String.eq(h, name), u => True{}, u => has_name(t, name))

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
def subst_node(t, id, v):
  match t:
    case KTerm{tag, name, n, q, kids, removed}:
      core_rebuild(KTerm{tag, name, n, q, subst_terms(kids, id, v), removed})

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
  kc(KTerm, String.eq(tg(t), "App"), u => core_apply(kid(t, 0), kid(t, 1)), u => t)

@unsafe
def core_apply(f, x):
  kc(KTerm, String.eq(tg(f), "Lam"), u => subst(kid(f, 0), ix(f), x), u => app(f, x))

@unsafe
def core_beta(
  +t: KTerm,
) -> KTerm:
  kc(KTerm, String.eq(tg(t), "App"), u => core_apply(core_beta(kid(t, 0)), kid(t, 1)), u => t)

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
    case KTerm{tag, name, id, quant, kids, removed}:
      kc(Bool, String.eq(tag, "Var"), u => False{},
        u => kc(Bool, core_subst_stable_terms(kids),
          u => kc(Bool, String.eq(tag, "App"),
            u => kc(Bool, String.eq(name, "") && U32.is_eq(id, 0) && U32.is_eq(quant, 0), u => core_subst_stable_app(kids, removed), u => False{}),
            u => True{}),
          u => False{}))

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


# Compact source Nat literals use the U32 quantity slot as payload, never id.
# All other fields are canonical and empty; consumers expose only one layer.
@unsafe
def core_nat(+t: KTerm) -> Bool:
  kc(Bool, String.eq(tg(t), "LitNat"), u => String.eq(nm(t), "") && U32.is_eq(ix(t), 0) && U32.is_eq(U32.add(qt(t), 0), qt(t)) && U32.is_eq(terms_len(ks(t)), 0) && List.is_empty(&2, String, rm(t)), u => False{})

@unsafe
def core_nat_make(+n: U32) -> KTerm:
  kt("LitNat", "", 0, n, Nil{})

@unsafe
def core_nat_step(+t: KTerm) -> KTerm:
  kc(KTerm, U32.is_eq(qt(t), 0), u => kt("Ctr", "Zero", 0, 1, Nil{}), u => kt("Ctr", "Succ", 0, 1, [core_nat_make(U32.sub(qt(t), 1))]))

@unsafe
def core_nat_type(+book: List<&2, KDef>, +ty: KTerm) -> Bool:
  String.eq(tg(ty), "ADT") && String.eq(nm(ty), "Nat") && List.is_empty(&2, String, rm(ty)) && db(lookup(book, "Nat"))
