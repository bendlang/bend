# Closed private data shapes. This is not public argument admission: callers
# must prove scalar roots and a closed first-order graph before using these.
# A shared residual budget bounds all record-field visits, including siblings.

@unsafe
def j_region_local_ok(+result: Maybe<&2,U32>) -> Bool:
  match result:
    case Some{fuel}: True{}
    case None{}: False{}

@unsafe
def j_region_local_array(+book: List<&2,KDef>, +ty: KTerm) -> Bool:
  kc(Bool, String.eq(tg(ty), "ADT") && String.eq(nm(ty), "Array") &&
    U32.is_eq(terms_len(ks(ty)), 1) && List.is_empty(&2, String, rm(ty)), u =>
    j_u32_native_ctor(book, "Array", "ALeaf") && j_u32_native_ctor(book, "Array", "ANode") &&
    j_primitive_type(book, wnf(book, kid(ty, 0)), "U32"), u => False{})

@unsafe
def j_region_local_sigma(+book: List<&2,KDef>, +ty: KTerm) -> Bool:
  kc(Bool, String.eq(tg(ty), "ADT") && String.eq(nm(ty), "Sigma") &&
    U32.is_eq(terms_len(ks(ty)), 4) && List.is_empty(&2, String, rm(ty)), u =>
    j_u32_native_ctor(book, "Sigma", "Tuple") && U32.is_eq(da(lookup(book, "Sigma")), 4), u => False{})

# After local-type admission, only flat scalar public results need record shells.
# Normalize aliases here so construction and elimination agree on the layout.
@unsafe
def j_region_local_vector(+book: List<&2,KDef>, +ty: KTerm) -> Bool:
  +head = wnf(book, ty)
  kc(Bool, j_region_local_sigma(book, head), u => True{}, u =>
    String.eq(dk(j_region_local_ctor_head(book, head)), "Ctr") && Bool.not(j_region_record(book, head)))

# Return only an eligible constructor header. Field types are checked by
# j_region_local_type, before a caller may lower construction or elimination.
@unsafe
def j_region_local_ctor(+book: List<&2,KDef>, +ty: KTerm) -> KDef:
  j_region_local_ctor_head(book, wnf(book, ty))

@unsafe
def j_region_local_ctor_head(+book: List<&2,KDef>, +ty: KTerm) -> KDef:
  +owner = lookup(book, nm(ty))
  +kind = wnf(book, dt(owner))
  kc(KDef, j_region_local_sigma(book, ty),
    u => j_region_local_one(dc(owner), True{}), u =>
    kc(KDef, String.eq(tg(ty), "ADT") && U32.is_eq(terms_len(ks(ty)), 0) &&
      List.is_empty(&2, String, rm(ty)) && String.eq(dk(owner), "ADT") &&
      Bool.not(db(owner)) && U32.is_eq(da(owner), 0) && U32.is_eq(dx(owner), 0) &&
      String.eq(tg(kind), "Typ") && U32.is_eq(terms_len(ks(kind)), 1) &&
      String.eq(tg(kid(kind, 0)), "Qua") &&
      (U32.is_eq(qt(kid(kind, 0)), 1) || U32.is_eq(qt(kid(kind, 0)), 2)),
      u => j_region_local_one(dc(owner), False{}), u => missing()))

@unsafe
def j_region_local_one(+ctors: List<&2,KDef>, +native: Bool) -> KDef:
  match ctors:
    case Con{c, Nil{}}:
      kc(KDef, String.eq(dk(c), "Ctr") && U32.is_eq(dx(c), 0) && U32.is_le(da(c), 32) &&
        kc(Bool, native, u => db(c) && String.eq(dn(c), "Tuple") && U32.is_eq(da(c), 2),
          u => Bool.not(db(c))), u => c, u => missing())
    case other: missing()

@unsafe
def j_region_local_fields(+book: List<&2,KDef>, +ty: KTerm) -> KTerm:
  +head = wnf(book, ty)
  +c = j_region_local_ctor_head(book, head)
  kc(KTerm, String.eq(dk(c), "Ctr"),
    u => j_specialize(book, dt(c), ks(head)), u => atom("Absent"))

@unsafe
def j_region_local_field_count(+book: List<&2,KDef>, +ty: KTerm) -> U32:
  da(j_region_local_ctor(book, ty))

@unsafe
def j_region_local_type(+book: List<&2,KDef>, +ty: KTerm) -> Bool:
  j_region_local_ok(j_region_local_check(book, ty, Nil{}, 256))

@unsafe
def j_region_local_check(+book: List<&2,KDef>, +ty: KTerm, +active: List<&2,String>, +fuel: U32) -> Maybe<&2,U32>:
  kc(Maybe<&2,U32>, U32.is_gt(fuel, 0), u =>
    j_region_local_check_head(book, wnf(book, ty), active, U32.sub(fuel, 1)), u => None{})

@unsafe
def j_region_local_check_head(+book: List<&2,KDef>, +ty: KTerm, +active: List<&2,String>, +fuel: U32) -> Maybe<&2,U32>:
  kc(Maybe<&2,U32>, j_region_scalar(book, ty), u => Some{fuel}, u =>
    kc(Maybe<&2,U32>, j_region_local_array(book, ty), u => Some{fuel}, u =>
    kc(Maybe<&2,U32>, j_fold_type(book, ty), u => Some{fuel}, u =>
    kc(Maybe<&2,U32>, Bool.not(has_name(active, nm(ty))), u =>
      j_region_local_record_check(book, ty, j_region_local_ctor_head(book, ty),
        kc(List<&2,String>, j_region_local_sigma(book, ty), u => active, u => Con{nm(ty), active}), fuel), u => None{}))))

@unsafe
def j_region_local_record_check(+book: List<&2,KDef>, +ty: KTerm, +c: KDef, +active: List<&2,String>, +fuel: U32) -> Maybe<&2,U32>:
  kc(Maybe<&2,U32>, String.eq(dk(c), "Ctr"), u =>
    j_region_local_fields_check(book, j_specialize(book, dt(c), ks(ty)), nm(ty), da(c), active, fuel), u => None{})

@unsafe
def j_region_local_fields_check(+book: List<&2,KDef>, +tel: KTerm, +owner: String, +left: U32, +active: List<&2,String>, +fuel: U32) -> Maybe<&2,U32>:
  kc(Maybe<&2,U32>, U32.is_gt(fuel, 0), u =>
    j_region_local_fields_head(book, wnf(book, tel), owner, left, active, U32.sub(fuel, 1)), u => None{})

@unsafe
def j_region_local_fields_head(+book: List<&2,KDef>, +tel: KTerm, +owner: String, +left: U32, +active: List<&2,String>, +fuel: U32) -> Maybe<&2,U32>:
  kc(Maybe<&2,U32>, U32.is_eq(left, 0), u =>
    kc(Maybe<&2,U32>, String.eq(tg(tel), "ADT") && String.eq(nm(tel), owner) &&
      List.is_empty(&2, String, rm(tel)), u => Some{fuel}, u => None{}), u =>
    kc(Maybe<&2,U32>, String.eq(tg(tel), "All") && Bool.not(U32.is_eq(qt(tel), 0)), u =>
      j_region_local_fields_next(book, kid(tel, 1), owner, U32.sub(left, 1), active,
        j_region_local_check(book, kid(tel, 0), active, fuel)), u => None{}))

@unsafe
def j_region_local_fields_next(+book: List<&2,KDef>, +tel: KTerm, +owner: String, +left: U32, +active: List<&2,String>, +result: Maybe<&2,U32>) -> Maybe<&2,U32>:
  match result:
    case Some{fuel}: j_region_local_fields_check(book, tel, owner, left, active, fuel)
    case None{}: None{}

# Erased parameters are not admitted for ordinary private helpers. Only the
# three explicitly validated native operations below have an erased U32 slot.
@unsafe
def j_region_local_signature(+book: List<&2,KDef>, +ty: KTerm, +left: U32) -> Bool:
  kc(Bool, U32.is_le(left, 32), u => j_region_local_signature_head(book, wnf(book, ty), left), u => False{})

@unsafe
def j_region_local_signature_head(+book: List<&2,KDef>, +ty: KTerm, +left: U32) -> Bool:
  kc(Bool, U32.is_eq(left, 0), u => j_region_local_type(book, ty), u =>
    kc(Bool, String.eq(tg(ty), "All") && Bool.not(U32.is_eq(qt(ty), 0)) && j_region_local_type(book, kid(ty, 0)),
      u => j_region_local_signature(book, kid(ty, 1), U32.sub(left, 1)), u => False{}))

@unsafe
def j_region_local_native(+book: List<&2,KDef>, +spine: KTerm) -> Bool:
  +name = nm(spine)
  kc(Bool, String.eq(tg(spine), "Call") && String.contains("|Array.new|Array.get|Array.set|", "|" ++ name ++ "|") &&
    U32.is_eq(terms_len(ks(spine)), kc(U32, String.eq(name, "Array.set"), u => 4, u => 3)), u =>
    kc(Bool, j_primitive_type(book, wnf(book, kid(spine, 0)), "U32"), u =>
      j_region_local_native_def(book, lookup(book, name), kid(spine, 0), terms_len(ks(spine))), u => False{}), u => False{})

@unsafe
def j_region_local_native_def(+book: List<&2,KDef>, +d: KDef, +element: KTerm, +arity: U32) -> Bool:
  +head = wnf(book, dt(d))
  kc(Bool, String.eq(dk(d), "Def") && db(d) && U32.is_eq(dx(d), 0) && U32.is_eq(da(d), arity) &&
    Bool.not(String.eq(tg(j_strip(dv(d))), "Foreign")) && String.eq(tg(head), "All") && U32.is_eq(qt(head), 0), u =>
    kc(Bool, j_region_local_element_kind(book, kid(head, 0), dn(d)), u =>
      j_region_local_native_args(book, j_app_type(head, element), dn(d), 1, arity), u => False{}), u => False{})

@unsafe
def j_region_local_element_kind(+book: List<&2,KDef>, +ty: KTerm, +name: String) -> Bool:
  +head = wnf(book, ty)
  String.eq(tg(head), "Typ") && U32.is_eq(terms_len(ks(head)), 1) && String.eq(tg(kid(head, 0)), "Qua") &&
  U32.is_eq(qt(kid(head, 0)), kc(U32, String.eq(name, "Array.set"), u => 1, u => 2))

@unsafe
def j_region_local_native_args(+book: List<&2,KDef>, +ty: KTerm, +name: String, +at: U32, +total: U32) -> Bool:
  +head = wnf(book, ty)
  kc(Bool, U32.is_eq(at, total), u =>
    kc(Bool, String.eq(name, "Array.get"), u => j_region_local_pair(book, head), u => j_region_local_array(book, head)), u =>
    kc(Bool, String.eq(tg(head), "All") && Bool.not(U32.is_eq(qt(head), 0)) &&
      j_region_local_native_input(book, wnf(book, kid(head, 0)), name, at), u =>
      j_region_local_native_args(book, kid(head, 1), name, U32.inc(at), total), u => False{}))

@unsafe
def j_region_local_native_input(+book: List<&2,KDef>, +ty: KTerm, +name: String, +at: U32) -> Bool:
  kc(Bool, U32.is_eq(at, 1), u =>
    kc(Bool, String.eq(name, "Array.new"), u => j_primitive_type(book, ty, "Nat"), u => j_region_local_array(book, ty)),
    u => j_primitive_type(book, ty, "U32"))

@unsafe
def j_region_local_pair(+book: List<&2,KDef>, +ty: KTerm) -> Bool:
  kc(Bool, j_region_local_sigma(book, ty), u =>
    j_region_local_pair_fields(book, wnf(book, j_region_local_fields(book, ty))), u => False{})

@unsafe
def j_region_local_pair_fields(+book: List<&2,KDef>, +tel: KTerm) -> Bool:
  +rest = wnf(book, kid(tel, 1))
  String.eq(tg(tel), "All") && Bool.not(U32.is_eq(qt(tel), 0)) && j_region_local_array(book, wnf(book, kid(tel, 0))) &&
  String.eq(tg(rest), "All") && Bool.not(U32.is_eq(qt(rest), 0)) && j_primitive_type(book, wnf(book, kid(rest, 0)), "U32") &&
  String.eq(tg(wnf(book, kid(rest, 1))), "ADT") && String.eq(nm(wnf(book, kid(rest, 1))), "Sigma")
