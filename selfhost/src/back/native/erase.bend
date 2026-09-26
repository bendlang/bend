law nc_live_count_head:
  for +book: List<&2, KDef>
  for +head: KTerm
  for +left: U32
  U32

# Erasure consumes annotate_book output. Type annotations determine erased
# arguments, constructor fields, lambda binders, and match-field arities.

law nc_erase:
  for +book: List<&2, KDef>
  for +t: KTerm
  KTerm

law nc_erase_list:
  for +book: List<&2, KDef>
  for +ts: List<&2, KTerm>
  List<&2, KTerm>

@unsafe
def nc_tele_fill(+book: List<&2, KDef>, +tel: KTerm, args: List<&2, KTerm>) -> KTerm:
  match args:
    case Nil{}: tel
    case Con{h, rest}:
      +head = wnf(book, tel)
      nc_tele_fill(book, subst(kid(head, 1), ix(head), h), rest)

@unsafe
def nc_live_count(+book: List<&2, KDef>, +tel: KTerm, +left: U32) -> U32:
  nt_choose(U32, U32.is_eq(left, 0), u => 0, u => nc_live_count_head(book, wnf(book, tel), left))

@unsafe
def nc_live_count_head(book, head, left):
  U32.add(nt_bool(Bool.not(U32.is_eq(qt(head), 0))), nc_live_count(book, kid(head, 1), U32.sub(left, 1)))

@unsafe
def nc_erase_args(
  +book: List<&2, KDef>,
  +tel: KTerm,
  +xs: List<&2, KTerm>,
) -> List<&2, KTerm>:
  match xs:
    case Nil{}: Nil{}
    case Con{h, rest}:
      +head = wnf(book, tel)
      nt_choose(List<&2, KTerm>, U32.is_eq(qt(head), 0),
        u => nc_erase_args(book, subst(kid(head, 1), ix(head), h), rest),
        u => Con{nc_erase(book, h), nc_erase_args(book, subst(kid(head, 1), ix(head), h), rest)})

@unsafe
def nc_erase_mat(+book: List<&2, KDef>, +t: KTerm, +adt: KTerm) -> KTerm:
  +ctr = lookup(dc(lookup(book, nm(adt))), nm(t))
  +count = nc_live_count(book, nc_tele_fill(book, dt(ctr), ks(adt)), da(ctr))
  kt("Mat", nt_choose(String, db(lookup(book, nm(adt))), u => nm(t), u => nc_ctor_identity(book, nm(t))), U32.inc(count), qt(t), nc_erase_list(book, ks(t)))

@unsafe
def nc_erase_annotated(+book: List<&2, KDef>, +t: KTerm, +ty: KTerm) -> KTerm:
  nt_choose(KTerm, String.eq(tg(ty), "Eql"), u => atom("Rfl"), u =>
  nt_choose(KTerm, String.eq(tg(t), "Ctr"),
    u => kt("Ctr", nt_choose(String, db(lookup(book, nm(ty))), u => nm(t), u => nc_ctor_identity(book, nm(t))), ix(t), qt(t), nc_erase_args(book, nc_tele_fill(book, dt(lookup(dc(lookup(book, nm(ty))), nm(t))), ks(ty)), ks(t))),
    u => nt_choose(KTerm, String.eq(tg(t), "Mat"),
      u => nc_erase_mat(book, t, wnf(book, kid(ty, 0))),
      u => nc_erase(book, t))))

@unsafe
def nc_erase_list(book, ts):
  match ts:
    case Nil{}: Nil{}
    case Con{h, rest}: Con{nc_erase(book, h), nc_erase_list(book, rest)}

@unsafe
def nc_erase_app(+book: List<&2, KDef>, +t: KTerm) -> KTerm:
  nt_choose(KTerm, String.eq(tg(kid(t, 0)), "Ann"),
    u => nt_choose(KTerm, U32.is_eq(qt(wnf(book, kid(kid(t, 0), 1))), 0), u => nc_erase(book, kid(t, 0)), u => kt(tg(t), nm(t), ix(t), qt(t), nc_erase_list(book, ks(t)))),
    u => kt(tg(t), nm(t), ix(t), qt(t), nc_erase_list(book, ks(t))))

@unsafe
def nc_erase(book, t):
  nt_choose(KTerm, String.eq(tg(t), "Var"), u => var(nm(t), ix(t)), u =>
  nt_choose(KTerm, String.eq(tg(t), "Ann"), u => nc_erase_annotated(book, kid(t, 0), wnf(book, kid(t, 1))), u =>
  nt_choose(KTerm, String.eq(tg(t), "Lam") && U32.is_eq(qt(t), 0), u => nc_erase(book, kid(t, 0)), u =>
  nt_choose(KTerm, String.eq(tg(t), "App"), u => nc_erase_app(book, t), u =>
    kt(tg(t), nt_choose(String, String.eq(tg(t), "Ctr") || String.eq(tg(t), "Mat"), u => nc_ctor_identity(book, nm(t)), u => nm(t)), ix(t), qt(t), nc_erase_list(book, ks(t)))))))
