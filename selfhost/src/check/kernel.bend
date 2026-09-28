import Base

# Bidirectional dependent checker. Errors are values, never success-shaped holes.
type KChecked is Data:
  KChecked{+term: KTerm, +typ: KTerm, +uses: List<&2, KTerm>, +error: String}

type KEnv is Data:
  KEnv{+book: List<&2, KDef>, +name: String, +lhs: KTerm, +pending: U32, +quantities: List<&2, KTerm>, +unsafe: Bool}

law infer_node:
  for +e: KEnv
  for +ctx: List<&2, KTerm>
  for +t: KTerm
  for +dem: U32
  for +sp: List<&2, KTerm>
  KChecked

law infer_var:
  for +ctx: List<&2, KTerm>
  for +t: KTerm
  for +dem: U32
  KChecked

law infer_ref:
  for +e: KEnv
  for +t: KTerm
  for +dem: U32
  for +sp: List<&2, KTerm>
  for +d: KDef
  KChecked

law infer_app:
  for +e: KEnv
  for +ctx: List<&2, KTerm>
  for +t: KTerm
  for +dem: U32
  for +r: KChecked
  KChecked

law infer_app_type:
  for +e: KEnv
  for +ctx: List<&2, KTerm>
  for +t: KTerm
  for +dem: U32
  for +r: KChecked
  for +ty: KTerm
  KChecked

law infer_adt:
  for +e: KEnv
  for +ctx: List<&2, KTerm>
  for +t: KTerm
  for +dem: U32
  for +d: KDef
  KChecked

law infer_adt_done:
  for +t: KTerm
  for +r: KChecked
  KChecked

law tele_check:
  for +e: KEnv
  for +ctx: List<&2, KTerm>
  for +tel: KTerm
  for +args: List<&2, KTerm>
  for +dem: U32
  KChecked

law tele_check_done:
  for +a: KChecked
  for +b: KChecked
  KChecked

law tele_fill_head:
  for +book: List<&2, KDef>
  for +tel: KTerm
  for +h: KTerm
  for +rest: List<&2, KTerm>
  KTerm

law check:
  for +e: KEnv
  for +ctx: List<&2, KTerm>
  for +t: KTerm
  for +dem: U32
  for +ty: KTerm
  KChecked

law check_node:
  for +e: KEnv
  for +ctx: List<&2, KTerm>
  for +t: KTerm
  for +dem: U32
  for +ty: KTerm
  KChecked

law check_fits:
  for +e: KEnv
  for +r: KChecked
  for +ty: KTerm
  KChecked

law check_lam:
  for +e: KEnv
  for +ctx: List<&2, KTerm>
  for +t: KTerm
  for +dem: U32
  for +ty: KTerm
  KChecked

law check_lam_q:
  for +e: KEnv
  for +ctx: List<&2, KTerm>
  for +t: KTerm
  for +dem: U32
  for +ty: KTerm
  for +q: U32
  KChecked

law check_lam_done:
  for +t: KTerm
  for +ty: KTerm
  for +q: U32
  for +r: KChecked
  KChecked

law check_ctr:
  for +e: KEnv
  for +ctx: List<&2, KTerm>
  for +t: KTerm
  for +dem: U32
  for +ty: KTerm
  KChecked

law check_ctr_found:
  for +e: KEnv
  for +ctx: List<&2, KTerm>
  for +t: KTerm
  for +dem: U32
  for +ty: KTerm
  for +ctr: KDef
  KChecked

law check_rfl:
  for +e: KEnv
  for +t: KTerm
  for +ty: KTerm
  KChecked

law check_let:
  for +e: KEnv
  for +outer: List<&2, KTerm>
  for +ctx: List<&2, KTerm>
  for +xs: List<&2, KTerm>
  for +dem: U32
  for +ty: KTerm
  for +bindings: List<&2, KTerm>
  for +us: List<&2, KTerm>
  KChecked

law check_let_value:
  for +e: KEnv
  for +outer: List<&2, KTerm>
  for +ctx: List<&2, KTerm>
  for +h: KTerm
  for +rest: List<&2, KTerm>
  for +dem: U32
  for +ty: KTerm
  for +bindings: List<&2, KTerm>
  for +us: List<&2, KTerm>
  for +r: KChecked
  KChecked

law check_let_kind:
  for +e: KEnv
  for +outer: List<&2, KTerm>
  for +ctx: List<&2, KTerm>
  for +h: KTerm
  for +rest: List<&2, KTerm>
  for +dem: U32
  for +ty: KTerm
  for +bindings: List<&2, KTerm>
  for +us: List<&2, KTerm>
  for +r: KChecked
  for +k: KChecked
  KChecked

law let_cells:
  for +body: KTerm
  for +bs: List<&2, KTerm>
  KTerm

law check_let_done:
  for +r: KChecked
  for +bs: List<&2, KTerm>
  for +us: List<&2, KTerm>
  KChecked

law dead_type:
  for +book: List<&2, KDef>
  for +ty: KTerm
  Bool

law check_mat:
  for +e: KEnv
  for +ctx: List<&2, KTerm>
  for +t: KTerm
  for +dem: U32
  for +ty: KTerm
  KChecked

law check_mat_type:
  for +e: KEnv
  for +ctx: List<&2, KTerm>
  for +t: KTerm
  for +dem: U32
  for +ty: KTerm
  for +a: KTerm
  KChecked

law check_mat_ctr:
  for +e: KEnv
  for +ctx: List<&2, KTerm>
  for +t: KTerm
  for +dem: U32
  for +ty: KTerm
  for +a: KTerm
  for +ctr: KDef
  KChecked

law mat_goal:
  for +book: List<&2, KDef>
  for +goal: KTerm
  for +tel: KTerm
  for +n: U32
  for +name: String
  for +xs: List<&2, KTerm>
  KTerm

law mat_goal_head:
  for +book: List<&2, KDef>
  for +goal: KTerm
  for +tel: KTerm
  for +n: U32
  for +name: String
  for +xs: List<&2, KTerm>
  KTerm

law mat_lhs:
  for +e: KEnv
  for +name: String
  for +tel: KTerm
  for +n: U32
  for +avoid: List<&2,KTerm>
  KEnv

law check_rwt:
  for +e: KEnv
  for +ctx: List<&2, KTerm>
  for +t: KTerm
  for +dem: U32
  for +ty: KTerm
  for +r: KChecked
  KChecked

law check_rwt_type:
  for +e: KEnv
  for +ctx: List<&2, KTerm>
  for +t: KTerm
  for +dem: U32
  for +ty: KTerm
  for +r: KChecked
  for +eq: KTerm
  KChecked

law check_rwt_goal:
  for +e: KEnv
  for +ctx: List<&2, KTerm>
  for +t: KTerm
  for +dem: U32
  for +ty: KTerm
  for +r: KChecked
  for +eq: KTerm
  for +fresh: U32
  KChecked

law tele_quantities_head:
  for +book: List<&2, KDef>
  for +ty: KTerm
  for +n: U32
  List<&2, KTerm>

law count_open:
  for +book: List<&2, KDef>
  U32

law check_open_message:
  for +n: U32
  String

law signature_fill_mode:
  for +d: KDef
  for +fill: KDef
  KDef

law constructor_names:
  for +done: List<&2, KDef>
  for +ctrs: List<&2, KDef>
  for +names: List<&2, String>
  String

law check_definition_type:
  for +book: List<&2, KDef>
  for +d: KDef
  for +e: KEnv
  for +r: KChecked
  KChecked

law check_foreign:
  for +book: List<&2, KDef>
  for +d: KDef
  String

law tele_tip_head:
  for +book: List<&2, KDef>
  for +t: KTerm
  KTerm

law check_adt_declaration:
  for +e: KEnv
  for +d: KDef
  String

law check_ctors:
  for +e: KEnv
  for +d: KDef
  for +ctrs: List<&2, KDef>
  for +kind: KTerm
  String

law check_ctors_next:
  for +e: KEnv
  for +d: KDef
  for +rest: List<&2, KDef>
  for +kind: KTerm
  for +err: String
  String

law check_ctor_tel:
  for +e: KEnv
  for +d: KDef
  for +tel: KTerm
  for +kind: KTerm
  for +params: U32
  for +fields: U32
  for +ctx: List<&2, KTerm>
  for +args: List<&2, KTerm>
  String

law check_ctor_head:
  for +e: KEnv
  for +d: KDef
  for +tel: KTerm
  for +kind: KTerm
  for +params: U32
  for +fields: U32
  for +ctx: List<&2, KTerm>
  for +args: List<&2, KTerm>
  String

law check_ctor_domain:
  for +e: KEnv
  for +d: KDef
  for +tel: KTerm
  for +kind: KTerm
  for +params: U32
  for +fields: U32
  for +ctx: List<&2, KTerm>
  for +args: List<&2, KTerm>
  for +r: KChecked
  String

law infer_template:
  for +e: KEnv
  for +t: KTerm
  for +dem: U32
  for +sp: List<&2, KTerm>
  for +d: KDef
  KChecked

law template_args:
  for +e: KEnv
  for +ty: KTerm
  for +sp: List<&2, KTerm>
  for +n: U32
  KChecked

law template_arg_head:
  for +e: KEnv
  for +ty: KTerm
  for +sp: List<&2, KTerm>
  for +n: U32
  KChecked

law template_arg_done:
  for +e: KEnv
  for +ty: KTerm
  for +h: KTerm
  for +rest: List<&2, KTerm>
  for +n: U32
  for +r: KChecked
  KChecked

law contains_self:
  for +todo: List<&2, KTerm>
  for +name: String
  Bool

law check_template_definition:
  for +book: List<&2, KDef>
  for +d: KDef
  for +ty: KTerm
  for +body: KTerm
  for +lhs: KTerm
  for +n: U32
  KChecked

law check_template_binder:
  for +book: List<&2, KDef>
  for +d: KDef
  for +ty: KTerm
  for +body: KTerm
  for +lhs: KTerm
  for +n: U32
  KChecked

law check_template_open:
  for +book: List<&2, KDef>
  for +d: KDef
  for +ty: KTerm
  for +body: KTerm
  for +lhs: KTerm
  for +n: U32
  for +name: String
  KChecked

@unsafe
def cb(
  +e: KEnv,
) -> List<&2, KDef>:
  match e:
    case KEnv{book, name, lhs, pending, quantities, unsafe}:
      book

@unsafe
def cn(
  +e: KEnv,
) -> String:
  match e:
    case KEnv{book, name, lhs, pending, quantities, unsafe}:
      name

@unsafe
def cl(
  +e: KEnv,
) -> KTerm:
  match e:
    case KEnv{book, name, lhs, pending, quantities, unsafe}:
      lhs

@unsafe
def cp(
  +e: KEnv,
) -> U32:
  match e:
    case KEnv{book, name, lhs, pending, quantities, unsafe}:
      pending

@unsafe
def cq(
  +e: KEnv,
) -> List<&2, KTerm>:
  match e:
    case KEnv{book, name, lhs, pending, quantities, unsafe}:
      quantities

@unsafe
def cu(
  +e: KEnv,
) -> Bool:
  match e:
    case KEnv{book, name, lhs, pending, quantities, unsafe}:
      unsafe

@unsafe
def ct(
  +r: KChecked,
) -> KTerm:
  match r:
    case KChecked{term, typ, uses, error}:
      term

@unsafe
def cy(
  +r: KChecked,
) -> KTerm:
  match r:
    case KChecked{term, typ, uses, error}:
      typ

@unsafe
def cs(
  +r: KChecked,
) -> List<&2, KTerm>:
  match r:
    case KChecked{term, typ, uses, error}:
      uses

@unsafe
def ce(
  +r: KChecked,
) -> String:
  match r:
    case KChecked{term, typ, uses, error}:
      error

@unsafe
def ok(
  +t: KTerm,
  +ty: KTerm,
  +us: List<&2, KTerm>,
) -> KChecked:
  KChecked{t, ty, us, ""}

@unsafe
def bad(
  +msg: String,
) -> KChecked:
  KChecked{atom("Error"), atom("Error"), Nil{}, msg}

@unsafe
def good(
  +r: KChecked,
) -> Bool:
  String.eq(ce(r), "")

@unsafe
def checked(
  +r: KChecked,
  +t: KTerm,
  +ty: KTerm,
) -> KChecked:
  kc(KChecked, good(r), u => ok(t, ty, cs(r)), u => r)

@unsafe
def both(
  +a: KChecked,
  +b: KChecked,
  +t: KTerm,
  +ty: KTerm,
  +join: Bool,
) -> KChecked:
  kc(KChecked, good(a), u => kc(KChecked, good(b), u => ok(t, ty, uses_merge(cs(a), cs(b), join)), u => b), u => a)

@unsafe
def ctx_get(
  +ctx: List<&2, KTerm>,
  +id: U32,
) -> KTerm:
  match ctx:
    case Nil{}:
      atom("Absent")
    case Con{h, t}:
      kc(KTerm, U32.is_eq(ix(h), id), u => h, u => ctx_get(t, id))

@unsafe
def ctx_bind(
  +ctx: List<&2, KTerm>,
  +id: U32,
  +q: U32,
  +name: String,
  +ty: KTerm,
) -> List<&2, KTerm>:
  Con{kt("Bind", name, id, q, Con{ty, Nil{}}), ctx}

@unsafe
def kindq(
  +e: KEnv,
  +q: U32,
) -> U32:
  kc(U32, cu(e) && U32.is_eq(q, 2), u => 1, u => q)

@unsafe
def kapply(
  +fn: KTerm,
  +x: KTerm,
) -> KTerm:
  kc(KTerm, String.eq(tg(strip(fn)), "Lam"), u => subst(kid(strip(fn), 0), ix(strip(fn)), x), u => app(fn, x))

@unsafe
def lhs_step(
  +e: KEnv,
  +x: KTerm,
) -> KEnv:
  kc(KEnv, U32.is_eq(cp(e), 0), u => e, u => KEnv{cb(e), cn(e), kapply(cl(e), x), U32.sub(cp(e), 1), cq(e), cu(e)})

@unsafe
def unargs(
  +t: KTerm,
  +acc: List<&2, KTerm>,
) -> List<&2, KTerm>:
  kc(List<&2, KTerm>, String.eq(tg(t), "App"), u => unargs(kid(t, 0), Con{kid(t, 1), acc}), u => acc)

@unsafe
def infer(
  +e: KEnv,
  +ctx: List<&2, KTerm>,
  +t: KTerm,
  +dem: U32,
  +sp: List<&2, KTerm>,
) -> KChecked:
  dg_trace(e, ctx, t, atom("Absent"), infer_node(e, ctx, core_beta(t), dem, sp))

@unsafe
def infer_node(e, ctx, t, dem, sp):
  kc(KChecked, String.eq(tg(t), "Var"), u => infer_var(ctx, t, dem),
   u => kc(KChecked, String.eq(tg(t), "Ref"), u => infer_ref(e, t, dem, sp, lookup(cb(e), nm(t))),
   u => kc(KChecked, String.eq(tg(t), "Typ"), u => checked(check(e, ctx, kid(t, 0), 0, atom("Qnt")), t, typ(1)),
   u => kc(KChecked, String.eq(tg(t), "Qnt"), u => ok(t, typ(1), Nil{}),
   u => kc(KChecked, String.eq(tg(t), "Qua"), u => ok(t, atom("Qnt"), Nil{}),
   u => kc(KChecked, String.eq(tg(t), "Min"), u => both(check(e, ctx, kid(t, 0), dem, atom("Qnt")), check(e, ctx, kid(t, 1), dem, atom("Qnt")), t, atom("Qnt"), False{}),
   u => kc(KChecked, String.eq(tg(t), "All"), u => both(check(e, ctx, kid(t, 0), 0, typ(kindq(e, qt(t)))), check(e, ctx_bind(ctx, ix(t), qt(t), nm(t), kid(t, 0)), kid(t, 1), 0, typ(1)), t, typ(1), False{}),
   u => kc(KChecked, String.eq(tg(t), "App"), u => infer_app(e, ctx, t, dem, infer(e, ctx, kid(t, 0), dem, Con{kid(t, 1), sp})),
   u => kc(KChecked, String.eq(tg(t), "ADT"), u => infer_adt(e, ctx, t, dem, lookup(cb(e), nm(t))),
   u => kc(KChecked, String.eq(tg(t), "Eql"), u => both(check(e, ctx, kid(t, 2), 0, typ(1)), both(check(e, ctx, kid(t, 0), 0, kid(t, 2)), check(e, ctx, kid(t, 1), 0, kid(t, 2)), t, typ(2), False{}), t, typ(2), False{}),
   u => kc(KChecked, String.eq(tg(t), "Ann"), u => both(check(e, ctx, kid(t, 1), 0, typ(1)), check(e, ctx, kid(t, 0), dem, kid(t, 1)), kid(t, 0), kid(t, 1), False{}),
   u => bad("cannot infer: annotation required"))))))))))))

@unsafe
def infer_var(ctx, t, dem):
  kc(KChecked, String.eq(tg(ctx_get(ctx, ix(t))), "Absent"), u => bad("unbound variable"), u => ok(t, kid(ctx_get(ctx, ix(t)), 0), Con{kt("Use", "", ix(t), dem, Nil{}), Nil{}}))

@unsafe
def infer_ref(e, t, dem, sp, d):
  kc(KChecked, String.eq(dk(d), "Absent"), u => bad("undefined name"),
   u => kc(KChecked, String.eq(dk(d), "ADT") && U32.is_gt(da(d), 0), u => bad("a family requires angle-bracket parameters"),
   u => kc(KChecked, U32.is_eq(dem, 0), u => ok(t, dt(d), Nil{}),
   u => kc(KChecked, String.eq(nm(t), cn(e)) && Bool.not(cu(e)) && Bool.not(descend_spine(cq(e), sp, unargs(cl(e), Nil{}))), u => bad("nondecreasing self-call"),
   u => kc(KChecked, String.eq(tg(dv(d)), "Absent") && Bool.not(db(d)) && Bool.not(cu(e)) && Bool.not(String.eq(nm(t), cn(e))), u => bad("live use of an unfilled law"),
   u => infer_template(e, t, dem, sp, d))))))

@unsafe
def infer_app(e, ctx, t, dem, r):
  kc(KChecked, good(r), u => infer_app_type(e, ctx, t, dem, r, wnf(cb(e), cy(r))), u => r)

@unsafe
def infer_app_type(e, ctx, t, dem, r, ty):
  kc(KChecked, String.eq(tg(ty), "All"), u => both(r, check(e, ctx, kid(t, 1), qdem(qt(ty), dem), kid(ty, 0)), t, subst(kid(ty, 1), ix(ty), kid(t, 1)), False{}), u => dg_bad_detail("application requires a function type", dg_text("a function type"), cy(r)))

@unsafe
def infer_adt(e, ctx, t, dem, d):
  kc(KChecked, String.eq(dk(d), "ADT") && U32.is_eq(terms_len(ks(t)), da(d)), u => infer_adt_done(t, tele_check(e, ctx, dt(d), ks(t), dem)), u => dg_adt_error(t, d))

@unsafe
def infer_adt_done(t, r):
  checked(r, t, cy(r))

@unsafe
def tele_check(e, ctx, tel, args, dem):
  match args:
    case Nil{}:
      ok(atom("Args"), tel, Nil{})
    case Con{h, t}:
      tele_check_cached_head(e, ctx, wnf(cb(e), tel), h, t, dem)

@unsafe
def tele_check_head(
  +e: KEnv,
  +ctx: List<&2, KTerm>,
  +tel: KTerm,
  +h: KTerm,
  +rest: List<&2, KTerm>,
  +dem: U32,
) -> KChecked:
  kc(KChecked, String.eq(tg(tel), "All"), u => tele_check_done(check(e, ctx, h, qdem(qt(tel), dem), kid(tel, 0)), tele_check(e, ctx, subst(kid(tel, 1), ix(tel), h), rest, dem)), u => bad("too many telescope arguments"))

@unsafe
def tele_check_done(a, b):
  both(a, b, ct(b), cy(b), False{})

@unsafe
def tele_fill(
  +book: List<&2, KDef>,
  +tel: KTerm,
  +args: List<&2, KTerm>,
) -> KTerm:
  match args:
    case Nil{}:
      tel
    case Con{h, t}:
      tele_fill_head(book, wnf(book, tel), h, t)

@unsafe
def tele_fill_head(book, tel, h, rest):
  kc(KTerm, String.eq(tg(tel), "All"), u => tele_fill(book, subst(kid(tel, 1), ix(tel), h), rest), u => atom("Error"))

@unsafe
def check(e, ctx, t, dem, ty):
  dg_trace(e, ctx, t, ty, check_node(e, ctx, core_beta(t), dem, ty))

@unsafe
def check_node(e, ctx, t, dem, ty):
  kc(KChecked, String.eq(tg(t), "Lam"), u => check_lam(e, ctx, t, dem, wnf(cb(e), ty)),
   u => kc(KChecked, String.eq(tg(t), "Ctr"), u => check_ctr(e, ctx, t, dem, wnf(cb(e), ty)),
   u => kc(KChecked, String.eq(tg(t), "Mat") || String.eq(tg(t), "Efq"), u => check_mat(e, ctx, t, dem, wnf(cb(e), ty)),
   u => kc(KChecked, String.eq(tg(t), "Rfl"), u => check_rfl(e, t, wnf(cb(e), ty)),
   u => kc(KChecked, String.eq(tg(t), "Hol"), u => bad("unresolved hole"),
   u => kc(KChecked, String.eq(tg(t), "Let"), u => check_let(e, ctx, ctx, ks(t), dem, ty, Nil{}, Nil{}),
   u => kc(KChecked, String.eq(tg(t), "Rwt"), u => check_rwt(e, ctx, t, dem, ty, infer(e, ctx, kid(t, 0), dem, Nil{})),
   u => check_fits(e, infer(e, ctx, t, dem, Nil{}), ty))))))))

@unsafe
def check_fits(e, r, ty):
  kc(KChecked, good(r), u => kc(KChecked, compare(cb(e), cy(r), ty, True{}), u => checked(r, ct(r), ty), u => dg_bad_detail("type mismatch", ty, cy(r))), u => r)

@unsafe
def check_lam(e, ctx, t, dem, ty):
  kc(KChecked, String.eq(tg(ty), "All"), u => check_lam_q(e, ctx, t, dem, ty, kc(U32, U32.is_eq(qt(t), 2) && U32.is_eq(qt(ty), 1), u => 2, u => qt(ty))), u => bad("lambda requires a function type"))

@unsafe
def check_lam_q(e, ctx, t, dem, ty, q):
  check_lam_done(t, ty, q, both(check(e, ctx, kid(ty, 0), 0, typ(kindq(e, q))), check(lhs_step(e, var(nm(t), ix(t))), ctx_bind(ctx, ix(t), q, nm(t), kid(ty, 0)), kid(t, 0), dem, subst(kid(ty, 1), ix(ty), var(nm(t), ix(t)))), t, ty, False{}))

@unsafe
def check_lam_done(t, ty, q, r):
  kc(KChecked, good(r), u => kc(KChecked, U32.is_gt(uses_get(cs(r), ix(t)), q), u => dg_quant_error("affine variable consumed more than allowed", nm(t), q, uses_get(cs(r), ix(t))), u => ok(t, ty, uses_del(cs(r), ix(t)))), u => r)

@unsafe
def check_ctr(e, ctx, t, dem, ty):
  kc(KChecked, String.eq(tg(ty), "ADT"), u => check_ctr_found(e, ctx, t, dem, ty, lookup(dc(lookup(cb(e), nm(ty))), nm(t))), u => bad("constructor requires a datatype goal"))

@unsafe
def check_ctr_found(e, ctx, t, dem, ty, ctr):
  kc(KChecked, Bool.not(String.eq(dk(ctr), "Absent")) && Bool.not(has_name(rm(ty), nm(t))) && U32.is_eq(da(ctr), terms_len(ks(t))), u => checked(tele_check(e, ctx, tele_fill(cb(e), dt(ctr), ks(ty)), ks(t), dem), t, ty), u => dg_ctor_error(e, t, ty, ctr))

@unsafe
def check_rfl(e, t, ty):
  kc(KChecked, String.eq(tg(ty), "Eql"), u => kc(KChecked, compare(cb(e), kid(ty, 0), kid(ty, 1), False{}), u => ok(t, ty, Nil{}), u => dg_bad_detail("reflexivity endpoints differ", kid(ty, 0), kid(ty, 1))), u => bad("reflexivity requires equality goal"))

@unsafe
def check_let(e, outer, ctx, xs, dem, ty, bindings, us):
  match xs:
    case Nil{}:
      bad("let has no body")
    case Con{h, rest}:
      kc(KChecked, String.eq(tg(h), "Bind"), u => check_let_value(e, outer, ctx, h, rest, dem, ty, bindings, us, infer(e, outer, kid(h, 0), qdem(qt(h), dem), Nil{})), u => check_let_done(check(e, ctx, let_cells(h, bindings), dem, ty), bindings, us))

@unsafe
def check_let_value(e, outer, ctx, h, rest, dem, ty, bindings, us, r):
  kc(KChecked, good(r), u => check_let_kind(e, outer, ctx, h, rest, dem, ty, bindings, us, r, check(e, outer, cy(r), 0, typ(kindq(e, qt(h))))), u => r)

@unsafe
def check_let_kind(e, outer, ctx, h, rest, dem, ty, bindings, us, r, k):
  kc(KChecked, good(k), u => check_let(e, outer, ctx_bind(ctx, ix(h), qt(h), nm(h), cy(r)), rest, dem, ty, Con{h, bindings}, uses_merge(us, cs(r), False{})), u => k)

@unsafe
def let_cells(body, bs):
  match bs:
    case Nil{}:
      body
    case Con{h, t}:
      let_cells(subst(body, ix(h), kt("Var", nm(h), ix(h), 0, Con{kid(h, 0), Nil{}})), t)

@unsafe
def check_let_done(r, bs, us):
  match bs:
    case Nil{}:
      kc(KChecked, good(r), u => ok(ct(r), cy(r), uses_merge(us, cs(r), False{})), u => r)
    case Con{h, t}:
      kc(KChecked, U32.is_gt(uses_get(cs(r), ix(h)), qt(h)), u => dg_quant_error("let binder consumed more than allowed", nm(h), qt(h), uses_get(cs(r), ix(h))), u => kc(KChecked, good(r), u => check_let_done(ok(ct(r), cy(r), uses_del(cs(r), ix(h))), t, us), u => r))

@unsafe
def remaining(
  +cs: List<&2, KDef>,
  +removed: List<&2, String>,
) -> List<&2, KDef>:
  match cs:
    case Nil{}:
      Nil{}
    case Con{h, t}:
      kc(List<&2, KDef>, has_name(removed, dn(h)), u => remaining(t, removed), u => Con{h, remaining(t, removed)})

@unsafe
def defs_empty(
  +ds: List<&2, KDef>,
) -> Bool:
  match ds:
    case Nil{}:
      True{}
    case Con{h, t}:
      False{}

@unsafe
def ctx_dead(
  +book: List<&2, KDef>,
  +ctx: List<&2, KTerm>,
) -> Bool:
  match ctx:
    case Nil{}:
      False{}
    case Con{h, t}:
      kc(Bool, U32.is_eq(qt(h), 0), u => ctx_dead(book, t), u => dead_type(book, wnf(book, kid(h, 0))) || ctx_dead(book, t))

@unsafe
def dead_type(book, ty):
  String.eq(tg(ty), "ADT") && String.eq(dk(lookup(book, nm(ty))), "ADT") && defs_empty(remaining(dc(lookup(book, nm(ty))), rm(ty)))

@unsafe
def check_mat(e, ctx, t, dem, ty):
  kc(KChecked, String.eq(tg(ty), "All"),
   u => kc(KChecked, Bool.not(U32.is_eq(dem, 0)) && U32.is_eq(qt(ty), 0), u => dg_bad_message("erased scrutinee in live match", dg_text("a live scrutinee (a - scrutinee matches only in a dead region)")),
   u => check_mat_type(e, ctx, t, dem, ty, wnf(cb(e), kid(ty, 0)))),
   u => bad("matcher requires a function type"))

@unsafe
def check_mat_type(e, ctx, t, dem, ty, a):
  kc(KChecked, String.eq(tg(a), "ADT") && String.eq(dk(lookup(cb(e), nm(a))), "ADT"),
   u => kc(KChecked, String.eq(tg(t), "Efq"),
   u => kc(KChecked, dead_type(cb(e), a) || ctx_dead(cb(e), ctx), u => ok(t, ty, Nil{}), u => dg_bad_detail("nonexhaustive match", dg_text("cases for " ++ dg_constructor_names(remaining(dc(lookup(cb(e), nm(a))), rm(a)))), t)),
   u => check_mat_ctr(e, ctx, t, dem, ty, a, lookup(remaining(dc(lookup(cb(e), nm(a))), rm(a)), nm(t)))),
   u => dg_bad_detail("match scrutinee requires a datatype", dg_text("a datatype"), kid(ty, 0)))

@unsafe
def check_mat_ctr(e, ctx, t, dem, ty, a, ctr):
  kc(KChecked, String.eq(dk(ctr), "Absent"), u => dg_bad_detail("unknown or duplicate match constructor", dg_text("a constructor of " ++ nm(a) ++ " (missing, or already matched)"), t),
   u => both(check(mat_lhs(e, nm(t), tele_fill(cb(e), dt(ctr), ks(a)), da(ctr), Con{t, Con{ty, ctx}}), ctx, kid(t, 0), dem, mat_goal(cb(e), ty, tele_fill(cb(e), dt(ctr), ks(a)), da(ctr), nm(t), Nil{})),
   check(e, ctx, kid(t, 1), dem, all(qt(ty), nm(ty), ix(ty), KTerm{tg(a), nm(a), ix(a), qt(a), ks(a), Con{nm(t), rm(a)}}, kid(ty, 1))), t, ty, True{}))

@unsafe
def mat_goal(book, goal, tel, n, name, xs):
  kc(KTerm, U32.is_eq(n, 0), u => subst(kid(goal, 1), ix(goal), kt("Ctr", name, 0, 0, norm_join(xs, Nil{}))), u => mat_goal_head(book, goal, wnf(book, tel), n, name, xs))

@unsafe
def mat_goal_head(book, goal, tel, n, name, xs):
  all(kc(U32, U32.is_eq(qt(tel), 0), u => 0, u => kc(U32, U32.is_eq(qt(tel), 1), u => qt(goal), u => qadd(qt(goal), qt(goal)))), nm(tel), ix(tel), kid(tel, 0), mat_goal(book, goal, kid(tel, 1), U32.sub(n, 1), name, norm_join(xs, Con{var(nm(tel), ix(tel)), Nil{}})))

@unsafe
def lhs_ext(
  +lhs: KTerm,
  +name: String,
  +tel: KTerm,
  +n: U32,
  +xs: List<&2, KTerm>,
  +fresh: U32,
) -> KTerm:
  kc(KTerm, U32.is_eq(n, 0), u => kapply(lhs, kt("Ctr", name, 0, 0, xs)), u => kt("Lam", nm(tel), fresh, qt(tel), Con{lhs_ext(lhs, name, kid(tel, 1), U32.sub(n, 1), norm_join(xs, Con{var(nm(tel), fresh), Nil{}}), U32.add(fresh, 1)), Nil{}}))

@unsafe
def mat_lhs(e, name, tel, n, avoid):
  # A nested match may reuse the same constructor telescope while the outer
  # column still binds its fields. Only names/quantities come from that telescope:
  # generated lambdas and constructor fields receive fresh matching identities.
  kc(KEnv, U32.is_eq(cp(e), 0), u => e, u => KEnv{cb(e), cn(e), lhs_ext(cl(e), name, tel, n, Nil{}, U32.add(1, norm_max_walk(Con{cl(e), Con{tel, avoid}}, norm_book_bound(cb(e))))), U32.add(U32.sub(cp(e), 1), n), cq(e), cu(e)})

@unsafe
def check_rwt(e, ctx, t, dem, ty, r):
  kc(KChecked, good(r), u => check_rwt_type(e, ctx, t, dem, ty, r, wnf(cb(e), cy(r))), u => r)

@unsafe
def check_rwt_type(e, ctx, t, dem, ty, r, eq):
  kc(KChecked, String.eq(tg(eq), "Eql"), u => check_rwt_goal(e, ctx, t, dem, ty, r, eq, U32.add(norm_book_bound(cb(e)), U32.add(norm_max_term(t), 1))), u => dg_bad_detail("rewrite requires equality evidence", dg_text("an equation {a == b : T}"), cy(r)))

@unsafe
def check_rwt_goal(e, ctx, t, dem, ty, r, eq, fresh):
  kc(KChecked, compare(cb(e), kapply(kapply(kid(t, 1), kid(eq, 1)), kid(t, 0)), ty, True{}),
   u => both(r, both(check(e, ctx, kid(t, 1), 0, all(1, "_", fresh, kid(eq, 2), all(1, "e", U32.add(fresh, 1), kt("Eql", "", 0, 0, Con{kid(eq, 0), Con{var("_", fresh), Con{kid(eq, 2), Nil{}}}}), typ(1)))), check(e, ctx, kid(t, 2), dem, kapply(kapply(kid(t, 1), kid(eq, 0)), atom("Rfl"))), t, ty, False{}), t, ty, False{}),
   u => dg_bad_detail("rewrite motive does not fit goal", ty, kapply(kapply(kid(t, 1), kid(eq, 1)), kid(t, 0))))

@unsafe
def tele_quantities(
  +book: List<&2, KDef>,
  +ty: KTerm,
  +n: U32,
) -> List<&2, KTerm>:
  kc(List<&2, KTerm>, U32.is_eq(n, 0), u => Nil{}, u => tele_quantities_head(book, wnf(book, ty), n))

@unsafe
def tele_quantities_head(book, ty, n):
  Con{qua(kc(U32, String.eq(tg(ty), "All"), u => qt(ty), u => 1)), tele_quantities(book, kid(ty, 1), U32.sub(n, 1))}

@unsafe
def declared(
  +d: KDef,
) -> KDef:
  KDef{dn(d), dk(d), da(d), dx(d), dt(d), atom("Absent"), dc(d), db(d), du(d)}

@unsafe
def check_book(
  +book: List<&2, KDef>,
) -> String:
  dg_result_error(check_book_diagnostic(book, Nil{}))

@unsafe
def check_open(
  +book: List<&2, KDef>,
) -> String:
  check_open_message(count_open(book))

@unsafe
def count_open(book):
  match book:
    case Nil{}:
      0
    case Con{d, rest}:
      U32.add(kc(U32, String.eq(dk(d), "Def") && String.eq(tg(dv(d)), "Absent") && Bool.not(db(d)), u => 1, u => 0), count_open(rest))

@unsafe
def check_open_message(n):
  kc(String, U32.is_eq(n, 0), u => "", u => U32.show(n) ++ " TODO" ++ kc(String, U32.is_eq(n, 1), u => "", u => "s") ++ " found.\nThe code is incomplete, and not a valid proof yet.")

@unsafe
def signature_mode(
  +d: KDef,
  +later: List<&2, KDef>,
) -> KDef:
  kc(KDef, String.eq(dk(d), "Def") && String.eq(tg(dv(d)), "Absent"), u => signature_fill_mode(d, lookup(later, dn(d))), u => d)

@unsafe
def signature_fill_mode(d, fill):
  kc(KDef, String.eq(dk(fill), "Def"), u => declared(fill), u => d)

# Every declaration is visible; only completed bodies may unfold. A separate
# event history retains duplicate/law diagnostics without hiding future types.
@unsafe
def check_declarations(
  +todo: List<&2,KDef>,
  +done: List<&2,KDef>,
) -> List<&2,KDef>:
  match todo:
    case Nil{}: done
    case Con{d, rest}:
      check_declarations(rest, book_put(done, kc(KDef, String.eq(tg(dv(d)), "Foreign"), u => d, u => declared(d))))

@unsafe
def check_event_install(
  +done: List<&2,KDef>,
  +d: KDef,
  +rest: List<&2,KDef>,
) -> List<&2,KDef>:
  kc(List<&2,KDef>, String.eq(dk(lookup(rest, dn(d))), "Absent"), u => book_put(done, d), u => done)

@unsafe
def event_error(
  +done: List<&2, KDef>,
  +d: KDef,
  +old: KDef,
) -> String:
  kc(String, String.eq(dk(old), "Absent"), u => kc(String, String.eq(dk(d), "ADT"), u => constructor_names(done, dc(d), Nil{}), u => ""), u => kc(String, String.eq(dk(old), "Def") && String.eq(dk(d), "Def") && String.eq(tg(dv(old)), "Absent") && Bool.not(String.eq(tg(dv(d)), "Absent")), u => kc(String, compare(done, dt(old), dt(d), False{}) && U32.is_eq(dx(old), dx(d)), u => "", u => "definition does not match prior law signature"), u => "duplicate declaration"))

@unsafe
def constructor_exists(
  +ds: List<&2, KDef>,
  +name: String,
) -> Bool:
  match ds:
    case Nil{}:
      False{}
    case Con{h, rest}:
      Bool.not(String.eq(dk(lookup(dc(h), name)), "Absent")) || constructor_exists(rest, name)

@unsafe
def constructor_names(done, ctrs, names):
  match ctrs:
    case Nil{}:
      ""
    case Con{h, rest}:
      kc(String, has_name(names, dn(h)) || constructor_exists(done, dn(h)), u => "duplicate constructor name", u => constructor_names(done, rest, Con{dn(h), names}))

@unsafe
def check_definition(
  +book: List<&2, KDef>,
  +d: KDef,
) -> String:
  ce(check_definition_result(book, d))

law check_definition_result:
  for +book: List<&2, KDef>
  for +d: KDef
  KChecked

@unsafe
def check_definition_result(book, d):
  check_definition_type(book, d, KEnv{book, dn(d), ref(dn(d)), 0, Nil{}, du(d)}, check(KEnv{book, dn(d), ref(dn(d)), 0, Nil{}, du(d)}, Nil{}, dt(d), 0, typ(1)))

@unsafe
def check_definition_type(book, d, e, r):
  # Legacy ADT/foreign checks use empty ce as success; good(bad("")) is True.
  kc(KChecked, good(r), u => kc(KChecked, String.eq(dk(d), "ADT"), u => bad(check_adt_declaration(e, d)),
   u => kc(KChecked, String.eq(tg(dv(d)), "Absent"), u => r, u => kc(KChecked, String.eq(tg(dv(d)), "Foreign"), u => bad(check_foreign(book, d)), u => check_template_definition(book, d, dt(d), dv(d), ref(dn(d)), dx(d))))), u => r)

@unsafe
def foreign_tip(
  +t: KTerm,
) -> KTerm:
  kc(KTerm, String.eq(tg(strip(t)), "All"), u => foreign_tip(kid(strip(t), 1)), u => strip(t))

@unsafe
def foreign_head(
  +t: KTerm,
) -> KTerm:
  kc(KTerm, String.eq(tg(t), "App"), u => foreign_head(kid(t, 0)), u => t)

@unsafe
def check_foreign(book, d):
  kc(String, U32.is_eq(dx(d), 0) && String.eq(tg(foreign_head(foreign_tip(dt(d)))), "Ref") && String.eq(nm(foreign_head(foreign_tip(dt(d)))), "IO") && String.eq(dk(lookup(book, "IO")), "Def") && db(lookup(book, "IO")), u => "", u => "foreign definition must return base IO directly")

@unsafe
def tele_tip(
  +book: List<&2, KDef>,
  +t: KTerm,
) -> KTerm:
  tele_tip_head(book, wnf(book, t))

@unsafe
def tele_tip_head(book, t):
  kc(KTerm, String.eq(tg(t), "All"), u => tele_tip(book, kid(t, 1)), u => t)

@unsafe
def check_adt_declaration(e, d):
  kc(String, String.eq(tg(tele_tip(cb(e), dt(d))), "Typ"), u => check_ctors(e, d, dc(d), dt(d)), u => "datatype declaration must return a kind")

@unsafe
def check_ctors(e, d, ctrs, kind):
  match ctrs:
    case Nil{}:
      ""
    case Con{h, t}:
      check_ctors_next(e, d, t, kind, check_ctor_tel(e, d, dt(h), kind, da(d), da(h), Nil{}, Nil{}))

@unsafe
def check_ctors_next(e, d, rest, kind, err):
  kc(String, String.eq(err, ""), u => check_ctors(e, d, rest, kind), u => err)

@unsafe
def check_ctor_tel(e, d, tel, kind, params, fields, ctx, args):
  kc(String, U32.is_eq(U32.add(params, fields), 0), u => kc(String, compare(cb(e), tel, kt("ADT", dn(d), 0, 0, args), False{}), u => "", u => "constructor result must apply family to its parameters"), u => check_ctor_head(e, d, wnf(cb(e), tel), kind, params, fields, ctx, args))

@unsafe
def check_ctor_head(e, d, tel, kind, params, fields, ctx, args):
  kc(String, String.eq(tg(tel), "All"), u => check_ctor_domain(e, d, tel, kind, params, fields, ctx, args, check(e, ctx, kid(tel, 0), 0, kc(KTerm, U32.is_eq(params, 0) && U32.is_eq(qt(tel), 1), u => kind, u => typ(qt(tel))))), u => "constructor telescope missing a binder")

@unsafe
def check_ctor_domain(e, d, tel, kind, params, fields, ctx, args, r):
  kc(String, good(r), u => check_ctor_tel(e, d, kid(tel, 1), kc(KTerm, U32.is_eq(params, 0), u => kind, u => subst(kid(wnf(cb(e), kind), 1), ix(wnf(cb(e), kind)), var(nm(tel), ix(tel)))), kc(U32, U32.is_eq(params, 0), u => 0, u => U32.sub(params, 1)), kc(U32, U32.is_eq(params, 0), u => U32.sub(fields, 1), u => fields), ctx_bind(ctx, ix(tel), qt(tel), nm(tel), kid(tel, 0)), kc(List<&2, KTerm>, U32.is_eq(params, 0), u => args, u => norm_join(args, Con{var(nm(tel), ix(tel)), Nil{}}))), u => ce(r))

@unsafe
def infer_template(e, t, dem, sp, d):
  kc(KChecked, U32.is_eq(dx(d), 0) || U32.is_gt(dx(lookup(cb(e), cn(e))), 0), u => ok(t, dt(d), Nil{}), u => checked(template_args(e, dt(d), sp, dx(d)), t, dt(d)))

@unsafe
def template_args(e, ty, sp, n):
  kc(KChecked, U32.is_eq(n, 0), u => ok(atom("Args"), ty, Nil{}), u => template_arg_head(e, wnf(cb(e), ty), sp, n))

@unsafe
def template_arg_head(e, ty, sp, n):
  match sp:
    case Nil{}:
      bad("template requires all closed comptime arguments")
    case Con{h, t}:
      kc(KChecked, String.eq(tg(ty), "All"), u => template_arg_done(e, ty, h, t, n, check(e, Nil{}, h, 0, kid(ty, 0))), u => bad("invalid template telescope"))

@unsafe
def template_arg_done(e, ty, h, rest, n, r):
  kc(KChecked, good(r), u => template_args(e, subst(kid(ty, 1), ix(ty), h), rest, U32.sub(n, 1)), u => bad("template argument is open or ill-typed"))

@unsafe
def self_pending(
  +d: KDef,
  +body: KTerm,
) -> U32:
  kc(U32, Bool.not(du(d)) && contains_self(Con{body, Nil{}}, dn(d)), u => U32.sub(da(d), dx(d)), u => 0)

@unsafe
def contains_self(todo, name):
  match todo:
    case Nil{}:
      False{}
    case Con{h, rest}:
      kc(Bool, String.eq(tg(h), "Ref") && String.eq(nm(h), name), u => True{}, u => contains_self(norm_join(ks(h), rest), name))

@unsafe
def check_template_definition(book, d, ty, body, lhs, n):
  kc(KChecked, U32.is_eq(n, 0), u => check(KEnv{book, dn(d), lhs, self_pending(d, body), tele_quantities(book, dt(d), da(d)), du(d)}, Nil{}, body, 1, ty), u => check_template_binder(book, d, wnf(book, ty), body, lhs, n))

@unsafe
def check_template_binder(book, d, ty, body, lhs, n):
  kc(KChecked, String.eq(tg(ty), "All"), u => check_template_open(book, d, ty, body, lhs, n, dn(d) ++ "~" ++ nm(ty) ++ U32.show(ix(ty))), u => bad("template telescope is too short"))

@unsafe
def check_template_open(book, d, ty, body, lhs, n, name):
  check_template_definition(book_put(book, KDef{name, "Def", 0, 0, kid(ty, 0), atom("Absent"), Nil{}, True{}, False{}}), d, subst(kid(ty, 1), ix(ty), ref(name)), kapply(body, ref(name)), app(lhs, ref(name)), U32.sub(n, 1))


law tele_check_cached_head:
  for +e: KEnv
  for +ctx: List<&2, KTerm>
  for +tel: KTerm
  for +h: KTerm
  for +rest: List<&2, KTerm>
  for +dem: U32
  KChecked

# A failed fact uses the original remaining traversal, avoiding repeated scans
# of dependent tails. The public tele_check_head retains its existing behavior.
law tele_check_legacy_head:
  for +e: KEnv
  for +ctx: List<&2, KTerm>
  for +tel: KTerm
  for +h: KTerm
  for +rest: List<&2, KTerm>
  for +dem: U32
  KChecked

@unsafe
def tele_check_cached_head(e, ctx, tel, h, rest, dem):
  kc(KChecked, String.eq(tg(tel), "All"),
    u => tele_check_after_head(e, ctx, tel, h, rest, dem, check(e, ctx, h, qdem(qt(tel), dem), kid(tel, 0))),
    u => bad("too many telescope arguments"))

@unsafe
def tele_check_static(
  +e: KEnv,
  +ctx: List<&2, KTerm>,
  +tel: KTerm,
  +args: List<&2, KTerm>,
  +dem: U32,
) -> KChecked:
  match args:
    case Nil{}: ok(atom("Args"), tel, Nil{})
    case Con{h, rest}:
      kc(KChecked, String.eq(tg(tel), "All"),
        u => tele_check_done(check(e, ctx, h, qdem(qt(tel), dem), kid(tel, 0)), tele_check_static(e, ctx, kid(tel, 1), rest, dem)),
        u => tele_check(e, ctx, tel, args, dem))

@unsafe
def tele_check_legacy(
  +e: KEnv,
  +ctx: List<&2, KTerm>,
  +tel: KTerm,
  +args: List<&2, KTerm>,
  +dem: U32,
) -> KChecked:
  match args:
    case Nil{}: ok(atom("Args"), tel, Nil{})
    case Con{h, rest}:
      tele_check_legacy_head(e, ctx, wnf(cb(e), tel), h, rest, dem)

@unsafe
def tele_check_legacy_head(e, ctx, tel, h, rest, dem):
  kc(KChecked, String.eq(tg(tel), "All"), u => tele_check_done(check(e, ctx, h, qdem(qt(tel), dem), kid(tel, 0)), tele_check_legacy(e, ctx, subst(kid(tel, 1), ix(tel), h), rest, dem)), u => bad("too many telescope arguments"))

law tele_check_after_head:
  for +e: KEnv
  for +ctx: List<&2, KTerm>
  for +tel: KTerm
  for +h: KTerm
  for +rest: List<&2, KTerm>
  for +dem: U32
  for +checked_head: KChecked
  KChecked

@unsafe
def tele_check_after_head(e, ctx, tel, h, rest, dem, checked_head):
  kc(KChecked, core_subst_stable(kid(tel, 1)),
    u => tele_check_done(checked_head, tele_check_static(e, ctx, kid(tel, 1), rest, dem)),
    u => tele_check_done(checked_head, tele_check_legacy(e, ctx, subst(kid(tel, 1), ix(tel), h), rest, dem)))
