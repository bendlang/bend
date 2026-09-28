import Base

# Type-directed readback for backends. Run only on a validated, specialized book.
# ka_type reconstructs types without repeating validation; the kernel never calls it.
law annotate_selected:
  for +book: List<&2, KDef>
  for +selected: List<&2, KDef>
  for +stops: List<&2, String>
  List<&2, KDef>

law ka_defs_except:
  for +book: List<&2, KDef>
  for +ds: List<&2, KDef>
  for +stops: List<&2, String>
  List<&2, KDef>

law ka_defs:
  for +book: List<&2, KDef>
  for +ds: List<&2, KDef>
  List<&2, KDef>

law ka_def:
  for +book: List<&2, KDef>
  for +d: KDef
  KDef

law annotate:
  for +e: KEnv
  for +ctx: List<&2, KTerm>
  for +t: KTerm
  for +ty: KTerm
  KTerm

law ka_node:
  for +e: KEnv
  for +ctx: List<&2, KTerm>
  for +t: KTerm
  for +ty: KTerm
  KTerm

law ka_type:
  for +e: KEnv
  for +ctx: List<&2, KTerm>
  for +t: KTerm
  KTerm

law ka_type_node:
  for +e: KEnv
  for +ctx: List<&2, KTerm>
  for +t: KTerm
  KTerm

law ka_type_app:
  for +e: KEnv
  for +t: KTerm
  for +fty: KTerm
  KTerm

law ka_lam:
  for +e: KEnv
  for +ctx: List<&2, KTerm>
  for +t: KTerm
  for +ty: KTerm
  KTerm

law ka_app:
  for +e: KEnv
  for +ctx: List<&2, KTerm>
  for +t: KTerm
  for +fty: KTerm
  KTerm

law ka_args_head:
  for +e: KEnv
  for +ctx: List<&2, KTerm>
  for +tel: KTerm
  for +h: KTerm
  for +rest: List<&2, KTerm>
  List<&2, KTerm>

law ka_mat:
  for +e: KEnv
  for +ctx: List<&2, KTerm>
  for +t: KTerm
  for +ty: KTerm
  for +a: KTerm
  KTerm

law ka_mat_ctr:
  for +e: KEnv
  for +ctx: List<&2, KTerm>
  for +t: KTerm
  for +ty: KTerm
  for +a: KTerm
  for +c: KDef
  KTerm

law ka_let:
  for +e: KEnv
  for +outer: List<&2, KTerm>
  for +ctx: List<&2, KTerm>
  for +xs: List<&2, KTerm>
  for +ty: KTerm
  List<&2, KTerm>

law ka_let_head:
  for +e: KEnv
  for +outer: List<&2, KTerm>
  for +ctx: List<&2, KTerm>
  for +h: KTerm
  for +rest: List<&2, KTerm>
  for +ty: KTerm
  for +vty: KTerm
  List<&2, KTerm>

law ka_rwt:
  for +e: KEnv
  for +ctx: List<&2, KTerm>
  for +t: KTerm
  for +eq: KTerm
  KTerm

@unsafe
def ka_wrap(
  +t: KTerm,
  +ty: KTerm,
) -> KTerm:
  kt("Ann", "", 0, 0, Con{t, Con{ty, Nil{}}})

@unsafe
def annotate_book(
  +book: List<&2, KDef>,
) -> List<&2, KDef>:
  ka_defs(book_context(book), book)

@unsafe
def annotate_except(
  +book: List<&2, KDef>,
  +stops: List<&2, String>,
) -> List<&2, KDef>:
  ka_defs_except(book_context(book), book, stops)

@unsafe
def annotate_selected(book, selected, stops):
  ka_defs_except(book_context(book), selected, stops)

@unsafe
def ka_defs_except(book, ds, stops):
  match ds:
    case Nil{}:
      Nil{}
    case Con{d, rest}:
      Con{kc(KDef, has_name(stops, dn(d)), u => d, u => ka_def(book, d)), ka_defs_except(book, rest, stops)}

@unsafe
def ka_defs(book, ds):
  match ds:
    case Nil{}:
      Nil{}
    case Con{d, rest}:
      Con{ka_def(book, d), ka_defs(book, rest)}

@unsafe
def ka_def(book, d):
  KDef{dn(d), dk(d), da(d), dx(d), dt(d), kc(KTerm, String.eq(tg(dv(d)), "Absent") || String.eq(tg(dv(d)), "Foreign") || U32.is_gt(dx(d), 0), u => dv(d), u => annotate(KEnv{book, dn(d), ref(dn(d)), 0, Nil{}, du(d)}, Nil{}, dv(d), dt(d))), dc(d), db(d), du(d)}

@unsafe
def annotate(e, ctx, t, ty):
  ka_wrap(ka_node(e, ctx, core_beta(t), wnf(cb(e), ty)), ty)

@unsafe
def ka_node(e, ctx, t, ty):
  kc(KTerm, String.eq(tg(t), "Ann"), u => ka_node(e, ctx, kid(t, 0), wnf(cb(e), kid(t, 1))),
   u => kc(KTerm, String.eq(tg(t), "Lam"), u => ka_lam(e, ctx, t, ty),
   u => kc(KTerm, String.eq(tg(t), "App"), u => kc(KTerm, ka_spine_eligible(t), u => ka_app_spine(e, ctx, t), u => ka_app(e, ctx, t, wnf(cb(e), ka_type(e, ctx, kid(t, 0))))),
   u => kc(KTerm, String.eq(tg(t), "Ctr"), u => kt("Ctr", nm(t), ix(t), qt(t), ka_args_cached(e, ctx, tele_fill(cb(e), dt(lookup(dc(lookup(cb(e), nm(ty))), nm(t))), ks(ty)), ks(t))),
   u => kc(KTerm, String.eq(tg(t), "Mat"), u => ka_mat(e, ctx, t, ty, wnf(cb(e), kid(ty, 0))),
   u => kc(KTerm, String.eq(tg(t), "Let"), u => kt("Let", nm(t), ix(t), qt(t), ka_let(e, ctx, ctx, ks(t), ty)),
   u => kc(KTerm, String.eq(tg(t), "Rwt"), u => ka_rwt(e, ctx, t, wnf(cb(e), ka_type(e, ctx, kid(t, 0)))),
   u => t)))))))

@unsafe
def ka_type(e, ctx, t):
  ka_type_node(e, ctx, core_beta(t))

@unsafe
def ka_type_node(e, ctx, t):
  kc(KTerm, String.eq(tg(t), "Var"), u => kid(ctx_get(ctx, ix(t)), 0),
   u => kc(KTerm, String.eq(tg(t), "Ref"), u => dt(lookup(cb(e), nm(t))),
   u => kc(KTerm, String.eq(tg(t), "Ann"), u => kid(t, 1),
   u => kc(KTerm, String.eq(tg(t), "App"), u => ka_type_app(e, t, wnf(cb(e), ka_type(e, ctx, kid(t, 0)))),
   u => kc(KTerm, String.eq(tg(t), "ADT"), u => tele_fill(cb(e), dt(lookup(cb(e), nm(t))), ks(t)),
   u => kc(KTerm, String.eq(tg(t), "Eql"), u => typ(2),
   u => kc(KTerm, String.eq(tg(t), "Qua") || String.eq(tg(t), "Min"), u => atom("Qnt"),
   u => kc(KTerm, String.eq(tg(t), "Typ") || String.eq(tg(t), "Qnt") || String.eq(tg(t), "All"), u => typ(1),
   u => atom("Error")))))))))

@unsafe
def ka_type_app(e, t, fty):
  subst(kid(fty, 1), ix(fty), kid(t, 1))

@unsafe
def ka_lam(e, ctx, t, ty):
  kt("Lam", nm(t), ix(t), kc(U32, U32.is_eq(qt(t), 2) && U32.is_eq(qt(ty), 1), u => 2, u => qt(ty)), Con{annotate(e, ctx_bind(ctx, ix(t), qt(ty), nm(t), kid(ty, 0)), kid(t, 0), subst(kid(ty, 1), ix(ty), var(nm(t), ix(t)))), Nil{}})

@unsafe
def ka_app(e, ctx, t, fty):
  app(annotate(e, ctx, kid(t, 0), fty), annotate(e, ctx, kid(t, 1), kid(fty, 0)))

@unsafe
def ka_args(
  +e: KEnv,
  +ctx: List<&2, KTerm>,
  +tel: KTerm,
  +xs: List<&2, KTerm>,
) -> List<&2, KTerm>:
  match xs:
    case Nil{}:
      Nil{}
    case Con{h, rest}:
      ka_args_head(e, ctx, wnf(cb(e), tel), h, rest)

@unsafe
def ka_args_head(e, ctx, tel, h, rest):
  Con{annotate(e, ctx, h, kid(tel, 0)), ka_args(e, ctx, subst(kid(tel, 1), ix(tel), h), rest)}

@unsafe
def ka_mat(e, ctx, t, ty, a):
  ka_mat_ctr(e, ctx, t, ty, a, lookup(dc(lookup(cb(e), nm(a))), nm(t)))

@unsafe
def ka_mat_ctr(e, ctx, t, ty, a, c):
  kt("Mat", nm(t), ix(t), qt(t), Con{annotate(e, ctx, kid(t, 0), mat_goal(cb(e), ty, tele_fill(cb(e), dt(c), ks(a)), da(c), nm(t), Nil{})), Con{annotate(e, ctx, mat_rest(cb(e), t, a), all(qt(ty), nm(ty), ix(ty), KTerm{tg(a), nm(a), ix(a), qt(a), ks(a), Con{nm(t), rm(a)}}, kid(ty, 1))), Nil{}}})

@unsafe
def ka_let(e, outer, ctx, xs, ty):
  match xs:
    case Nil{}:
      Nil{}
    case Con{h, rest}:
      kc(List<&2, KTerm>, String.eq(tg(h), "Bind"), u => ka_let_head(e, outer, ctx, h, rest, ty, ka_type(e, outer, kid(h, 0))), u => Con{annotate(e, ctx, h, ty), Nil{}})

@unsafe
def ka_let_head(e, outer, ctx, h, rest, ty, vty):
  Con{kt("Bind", nm(h), ix(h), qt(h), Con{annotate(e, outer, kid(h, 0), vty), Nil{}}), ka_let(e, outer, ctx_bind(ctx, ix(h), qt(h), nm(h), vty), subst_terms(rest, ix(h), kt("Var", nm(h), ix(h), 0, Con{kid(h, 0), Nil{}})), ty)}

@unsafe
def ka_rwt(e, ctx, t, eq):
  kt("Rwt", nm(t), ix(t), qt(t), Con{annotate(e, ctx, kid(t, 0), eq), Con{kid(t, 1), Con{annotate(e, ctx, kid(t, 2), kapply(kapply(kid(t, 1), kid(eq, 0)), atom("Rfl"))), Nil{}}}})


# A Ref/Var-headed application spine has no beta-redex in its function prefix.
# Infer each intermediate function type once, preserving the old Ann structure.
type KAnnotatedSpine is Data:
  KAnnotatedSpine{+node: KTerm, +typ: KTerm}

law ka_spine_eligible:
  for +t: KTerm
  Bool

law ka_spine_finish:
  for +e: KEnv
  for +ctx: List<&2, KTerm>
  for +arg: KTerm
  for +r: KAnnotatedSpine
  KAnnotatedSpine

law ka_spine_step:
  for +e: KEnv
  for +ctx: List<&2, KTerm>
  for +arg: KTerm
  for +node: KTerm
  for +fty: KTerm
  KAnnotatedSpine

law ka_app_spine:
  for +e: KEnv
  for +ctx: List<&2, KTerm>
  for +t: KTerm
  KTerm

law ka_app_spine_root:
  for +e: KEnv
  for +ctx: List<&2, KTerm>
  for +arg: KTerm
  for +node: KTerm
  for +fty: KTerm
  KTerm

@unsafe
def ka_spine_eligible(t):
  kc(Bool, String.eq(tg(t), "App"), u => ka_spine_eligible(kid(t, 0)), u => String.eq(tg(t), "Ref") || String.eq(tg(t), "Var"))

@unsafe
def ka_spine(
  +e: KEnv,
  +ctx: List<&2, KTerm>,
  +t: KTerm,
) -> KAnnotatedSpine:
  kc(KAnnotatedSpine, String.eq(tg(t), "App"), u => ka_spine_finish(e, ctx, kid(t, 1), ka_spine(e, ctx, kid(t, 0))), u => KAnnotatedSpine{t, ka_type(e, ctx, t)})

@unsafe
def ka_spine_finish(e, ctx, arg, r):
  match r:
    case KAnnotatedSpine{node, ty}: ka_spine_step(e, ctx, arg, node, wnf(cb(e), ty))

@unsafe
def ka_spine_step(e, ctx, arg, node, fty):
  KAnnotatedSpine{ka_app_spine_root(e, ctx, arg, node, fty), subst(kid(fty, 1), ix(fty), arg)}

@unsafe
def ka_app_spine(e, ctx, t):
  ka_app_spine_finish(e, ctx, kid(t, 1), ka_spine(e, ctx, kid(t, 0)))

law ka_app_spine_finish:
  for +e: KEnv
  for +ctx: List<&2, KTerm>
  for +arg: KTerm
  for +r: KAnnotatedSpine
  KTerm

@unsafe
def ka_app_spine_finish(e, ctx, arg, r):
  match r:
    case KAnnotatedSpine{node, ty}: ka_app_spine_root(e, ctx, arg, node, wnf(cb(e), ty))

@unsafe
def ka_app_spine_root(e, ctx, arg, node, fty):
  app(ka_wrap(node, fty), annotate(e, ctx, arg, kid(fty, 0)))

# Reuse a closed tail with only inert canonical Apps along its literal All spine.
# Ref/Ann/other heads restart analysis after ordinary weak-head normalization.
law ka_args_cached:
  for +e: KEnv
  for +ctx: List<&2, KTerm>
  for +tel: KTerm
  for +xs: List<&2, KTerm>
  List<&2, KTerm>

law ka_args_cached_head:
  for +e: KEnv
  for +ctx: List<&2, KTerm>
  for +tel: KTerm
  for +h: KTerm
  for +rest: List<&2, KTerm>
  List<&2, KTerm>

@unsafe
def ka_args_cached(e, ctx, tel, xs):
  match xs:
    case Nil{}: Nil{}
    case Con{h, rest}:
      ka_args_cached_head(e, ctx, wnf(cb(e), tel), h, rest)

@unsafe
def ka_args_cached_head(e, ctx, tel, h, rest):
  kc(List<&2, KTerm>, String.eq(tg(tel), "All"),
    u => ka_args_after_head(e, ctx, tel, h, rest, annotate(e, ctx, h, kid(tel, 0))),
    u => ka_args_head(e, ctx, tel, h, rest))

@unsafe
def ka_args_static(
  +e: KEnv,
  +ctx: List<&2, KTerm>,
  +tel: KTerm,
  +xs: List<&2, KTerm>,
) -> List<&2, KTerm>:
  match xs:
    case Nil{}: Nil{}
    case Con{h, rest}:
      kc(List<&2, KTerm>, String.eq(tg(tel), "All"),
        u => Con{annotate(e, ctx, h, kid(tel, 0)), ka_args_static(e, ctx, kid(tel, 1), rest)},
        u => ka_args_cached(e, ctx, tel, xs))

law ka_args_after_head:
  for +e: KEnv
  for +ctx: List<&2, KTerm>
  for +tel: KTerm
  for +h: KTerm
  for +rest: List<&2, KTerm>
  for +annotated: KTerm
  List<&2, KTerm>

@unsafe
def ka_args_after_head(e, ctx, tel, h, rest, annotated):
  kc(List<&2, KTerm>, core_subst_stable(kid(tel, 1)),
    u => Con{annotated, ka_args_static(e, ctx, kid(tel, 1), rest)},
    u => Con{annotated, ka_args(e, ctx, subst(kid(tel, 1), ix(tel), h), rest)})
