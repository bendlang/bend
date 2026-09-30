# Prebind constructor fields without raising the matcher's public arity.
# Only a literal, unlifted lambda arm with live fields and remaining arguments
# qualifies. The result keeps the original arity, code, null env and bound slice.
# Preserve project, its length read, slice and apply's post-slice branches, even
# when trusted foreign values supply an unusual field vector or slice method.

@unsafe
def j_arm_live_fields(+tel: KTerm, +owner: String, +at: U32) -> Maybe<&2,U32>:
  kc(Maybe<&2,U32>, String.eq(tg(tel), "All"),
    u => kc(Maybe<&2,U32>, Bool.not(U32.is_eq(qt(tel), 0)),
      u => j_arm_live_fields(kid(tel, 1), owner, U32.inc(at)), u => None{}),
    u => kc(Maybe<&2,U32>, String.eq(tg(tel), "ADT") && String.eq(nm(tel), owner), u => Some{at}, u => None{}))

@unsafe
def j_arm_lambdas(+book: List<&2,KDef>, +t: KTerm, +ty: KTerm, +at: U32) -> Maybe<&2,U32>:
  kc(Maybe<&2,U32>, String.eq(tg(t), "Ann"),
    u => j_arm_lambdas(book, kid(t, 0), kid(t, 1), at), u =>
  kc(Maybe<&2,U32>, String.eq(tg(t), "Lam"),
    u => j_arm_lambda_type(book, t, wnf(book, ty), at), u => Some{at}))

@unsafe
def j_arm_lambda_type(+book: List<&2,KDef>, +t: KTerm, +ty: KTerm, +at: U32) -> Maybe<&2,U32>:
  kc(Maybe<&2,U32>, String.eq(j_l_name(t), "") && String.eq(tg(ty), "All"),
    u => j_arm_lambdas(book, kid(t, 0), subst(kid(ty, 1), ix(ty), var(nm(t), ix(t))), U32.inc(at)), u => None{})

@unsafe
def j_arm_worker(+book: List<&2,KDef>, +env: List<&2,KTerm>, +t: KTerm, +ty: KTerm) -> Maybe<&2,String>:
  kc(Maybe<&2,String>, String.eq(tg(ty), "All") && Bool.not(U32.is_eq(qt(ty), 0)) && String.eq(tg(j_strip(kid(t, 0))), "Lam"),
    u => j_arm_owned(book, env, t, ty, wnf(book, kid(ty, 0))), u => None{})

@unsafe
def j_arm_owned(+book: List<&2,KDef>, +env: List<&2,KTerm>, +t: KTerm, +ty: KTerm, +domain: KTerm) -> Maybe<&2,String>:
  +owner = lookup(book, nm(domain))
  +ctor = lookup(dc(owner), nm(t))
  +armty = j_arm_type(book, ty, nm(t))
  kc(Maybe<&2,String>, String.eq(tg(domain), "ADT") && String.eq(dk(owner), "ADT") && String.eq(dk(ctor), "Ctr") && Bool.not(has_name(rm(domain), nm(t))),
    u => j_arm_sizes(book, env, t, armty,
      j_arm_live_fields(j_specialize(book, dt(ctor), ks(domain)), nm(domain), 0),
      j_arm_lambdas(book, kid(t, 0), armty, 0)), u => None{})

@unsafe
def j_arm_sizes(+book: List<&2,KDef>, +env: List<&2,KTerm>, +t: KTerm, +armty: KTerm, +fields: Maybe<&2,U32>, +arity: Maybe<&2,U32>) -> Maybe<&2,String>:
  match fields arity:
    case Some{count} Some{total}:
      kc(Maybe<&2,String>, U32.is_gt(count, 0) && U32.is_lt(count, total),
        u => Some{j_arm_code(nm(t), count, total, j_lambda_code(book, env, kid(t, 0), armty, 0))}, u => None{})
    case _ _: None{}

@unsafe
def j_arm_code(+name: String, +count: U32, +total: U32, +body: String) -> String:
  "(/* prebind-arm */matcher1p(" ++ j_quote(name) ++ "," ++ U32.show(count) ++ "," ++ U32.show(total) ++ ",()=>(0,function(a){" ++ body ++ "})))"

@unsafe
def j_arm_selected(+book: List<&2,KDef>, +env: List<&2,KTerm>, +t: KTerm, +ty: KTerm, +worker: Maybe<&2,String>) -> String:
  match worker:
    case Some{code}: code
    case None{}:
      "matcher1(" ++ j_quote(nm(t)) ++ ",()=>" ++ j_expr(book, env, kid(t, 0), j_arm_type(book, ty, nm(t)), False{}) ++ ")"
