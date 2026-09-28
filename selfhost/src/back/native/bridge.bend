# Checked-core lowering to native continuation segments.
# The uniform representation is one word per live value. Scalar primitives use
# immediate words; general constructors and closures use runtime heap nodes.

type NC_Literal is Data:
  NC_Literal{+valid: Bool, +value: U32}

type NC_Binding is Data:
  NC_Binding{+id: U32, +word: String}

type NC_Code is Data:
  NC_Code{+body: String, +segments: List<&2, N_Segment>, +fresh: U32, +error: String}

@unsafe
def nc_word(+id: U32, +env: List<&2, NC_Binding>) -> String:
  match env:
    case Nil{}: "NATIVE_UNBOUND_VARIABLE"
    case Con{NC_Binding{+at, +word}, +rest}:
      nt_choose(String, U32.is_eq(id, at), u => word, u => nc_word(id, rest))

@unsafe
def nc_words(+env: List<&2, NC_Binding>) -> List<&2, String>:
  match env:
    case Nil{}: Nil{}
    case Con{NC_Binding{+id, +word}, +rest}: Con{word, nc_words(rest)}

@unsafe
def nc_params(+env: List<&2, NC_Binding>) -> List<&2, N_Param>:
  match env:
    case Nil{}: Nil{}
    case Con{NC_Binding{+id, +word}, +rest}: Con{N_Param{word, N_W64{}}, nc_params(rest)}

@unsafe
def nc_slots(+env: List<&2, NC_Binding>, +i: U32) -> List<&2, String>:
  match env:
    case Nil{}: Nil{}
    case Con{+h, +rest}: Con{U32.show(i), nc_slots(rest, U32.inc(i))}

@unsafe
def nc_body(+x: NC_Code) -> String:
  match x:
    case NC_Code{+body, +segs, +n, +err}: body

@unsafe
def nc_segs(+x: NC_Code) -> List<&2, N_Segment>:
  match x:
    case NC_Code{+body, +segs, +n, +err}: segs

@unsafe
def nc_fresh(+x: NC_Code) -> U32:
  match x:
    case NC_Code{+body, +segs, +n, +err}: n

@unsafe
def nc_error(+x: NC_Code) -> String:
  match x:
    case NC_Code{+body, +segs, +n, +err}: err

@unsafe
def nc_first_error(+a: NC_Code, +b: NC_Code) -> String:
  nt_choose(String, String.eq(nc_error(a), ""), u => nc_error(b), u => nc_error(a))

@unsafe
def nc_return(+w: String, +n: U32) -> NC_Code:
  NC_Code{ne_ret([w]), Nil{}, n, ""}

@unsafe
def nc_fail(+msg: String, +n: U32) -> NC_Code:
  NC_Code{"", Nil{}, n, msg}

@unsafe
def nc_name(+n: U32) -> String:
  "native_k_" ++ U32.show(n)

@unsafe
def nc_id(+n: U32) -> U32:
  U32.sub(4294967295, n)

@unsafe
def nc_binding(+id: U32) -> NC_Binding:
  NC_Binding{id, "v_" ++ U32.show(id)}

@unsafe
def nc_cut_task(+next: String, +ws: List<&2, String>, emitted: N_Emitted) -> String:
  match emitted:
    case N_Emitted{code, word, n}:
      code ++ "WL_CONT = term_tsk(" ++ nt_fid(next) ++ ", " ++ word ++ ");\nWL_IDX = " ++ U32.show(nt_count(String, ws)) ++ ";\n"

@unsafe
def nc_cut(+ws: List<&2, String>, +next: String, +n: U32) -> String:
  "if (seq) {\n" ++ ne_frame(ws, next) ++ "} else {\n" ++ nc_cut_task(next, ws, ne_task(next, 1, ws, "WL_CONT", "WL_IDX", n)) ++ "}\n"

law nc_occurs:
  for +t: KTerm
  for +id: U32
  Bool

law nc_lower_live:
  for +book: List<&2, KDef>
  for +t: KTerm
  for +env: List<&2, NC_Binding>
  for +n: U32
  NC_Code

@unsafe
def nc_occurs_list(
  +ts: List<&2, KTerm>,
  +id: U32,
) -> Bool:
  match ts:
    case Nil{}: False{}
    case Con{h, t}: nc_occurs(h, id) || nc_occurs_list(t, id)

@unsafe
def nc_occurs(t, id):
  nt_choose(Bool, String.eq(tg(t), "Var"), u => U32.is_eq(ix(t), id), u => nc_occurs_list(ks(t), id))

@unsafe
def nc_live_env(env: List<&2, NC_Binding>, +t: KTerm) -> List<&2, NC_Binding>:
  match env:
    case Nil{}: Nil{}
    case Con{NC_Binding{+id, +word}, +rest}:
      nt_choose(List<&2, NC_Binding>, nc_occurs(t, id), u => Con{NC_Binding{id, word}, nc_live_env(rest, t)}, u => nc_live_env(rest, t))

@unsafe
def nc_remove_env(env: List<&2, NC_Binding>, +id: U32) -> List<&2, NC_Binding>:
  match env:
    case Nil{}: Nil{}
    case Con{NC_Binding{+at, +word}, +rest}:
      nt_choose(List<&2, NC_Binding>, U32.is_eq(at, id), u => rest, u => Con{NC_Binding{at, word}, nc_remove_env(rest, id)})

@unsafe
def nc_drop_dead(env: List<&2, NC_Binding>, +t: KTerm) -> String:
  match env:
    case Nil{}: ""
    case Con{NC_Binding{+id, +word}, rest}:
      nt_choose(String, nc_occurs(t, id), u => "", u => "term_sink(e, " ++ word ++ ");\n") ++ nc_drop_dead(rest, t)

@unsafe
def nc_share_env(env: List<&2, NC_Binding>, +a: KTerm, +b: KTerm) -> String:
  match env:
    case Nil{}: ""
    case Con{NC_Binding{+id, +word}, rest}:
      nt_choose(String, nc_occurs(a, id) && nc_occurs(b, id), u => word ++ " = term_keep(e, " ++ word ++ ");\n", u => "") ++ nc_share_env(rest, a, b)

@unsafe
def nc_prepend(code: String, x: NC_Code) -> NC_Code:
  match x:
    case NC_Code{body, segs, fresh, err}: NC_Code{code ++ body, segs, fresh, err}

@unsafe
def nc_lower(
  +book: List<&2, KDef>,
  +t: KTerm,
  +env: List<&2, NC_Binding>,
  +n: U32,
) -> NC_Code:
  nc_prepend(nc_drop_dead(env, t), nc_lower_live(book, t, nc_live_env(env, t), n))

@unsafe
def nc_let(+book: List<&2, KDef>, +value: KTerm, +body: KTerm, +env: List<&2, NC_Binding>, +id: U32, +n: U32) -> NC_Code:
  +next = nc_name(n)
  +held = nc_live_env(env, body)
  +newenv = List.append(&2, NC_Binding, held, [nc_binding(id)])
  +rest = nc_lower(book, body, newenv, U32.inc(n))
  +val = nc_lower(book, value, nc_live_env(env, value), nc_fresh(rest))
  +seg : N_Segment = N_Segment{next, nc_params(newenv), 1, N_Frame{nt_count(NC_Binding, held), nc_slots(held, 0)}, nc_body(rest), Nil{}, False{}, False{}, False{}, False{}}
  NC_Code{nc_share_env(env, value, body) ++ nc_cut(nc_words(held), next, nc_fresh(val)) ++ nc_body(val), Con{seg, nt_append(N_Segment, nc_segs(rest), nc_segs(val))}, nc_fresh(val), nc_first_error(rest, val)}

@unsafe
def nc_closure_result(+s: N_Segment, +body: NC_Code, +emitted: N_Emitted) -> NC_Code:
  match emitted:
    case N_Emitted{+code, +word, +fresh}:
      NC_Code{code ++ ne_ret([word]), Con{s, nc_segs(body)}, fresh, nc_error(body)}

@unsafe
def nc_lambda(+book: List<&2, KDef>, +t: KTerm, +env: List<&2, NC_Binding>, +n: U32) -> NC_Code:
  +name = nc_name(n)
  +params = List.append(&2, NC_Binding, env, [nc_binding(ix(t))])
  +body = nc_lower(book, kid(t, 0), params, U32.inc(n))
  +s : N_Segment = N_Segment{name, nc_params(params), 1, N_Direct{}, nc_body(body), Nil{}, False{}, False{}, False{}, False{}}
  nc_closure_result(s, body, ne_closure(name, nc_words(env), nc_fresh(body)))

@unsafe
def nc_mklet(+id: U32, +val: KTerm, +body: KTerm) -> KTerm:
  kt("Let", "", 0, 0, [kt("Bind", "", id, 1, [val]), body])

@unsafe
def nc_app_slow(+book: List<&2, KDef>, +t: KTerm, +env: List<&2, NC_Binding>, +n: U32) -> NC_Code:
  +f = nc_id(n)
  +a = nc_id(U32.inc(n))
  nc_lower(book, nc_mklet(f, kid(t, 0), nc_mklet(a, kid(t, 1), kt("NApply", "", 0, 0, [var("", f), var("", a)]))), env, U32.add(n, 2))

@unsafe
def nc_values(+xs: List<&2, KTerm>, +env: List<&2, NC_Binding>) -> List<&2, String>:
  match xs:
    case Nil{}: Nil{}
    case Con{+h, +t}: Con{nc_word(ix(h), env), nc_values(t, env)}

@unsafe
def nc_sequence(+tag: String, +name: String, +xs: List<&2, KTerm>, +acc: List<&2, KTerm>, +n: U32) -> KTerm:
  match xs:
    case Nil{}: kt(tag, name, 0, 0, List.reverse(&2, KTerm, acc))
    case Con{+h, +t}: nc_mklet(nc_id(n), h, nc_sequence(tag, name, t, Con{var("", nc_id(n)), acc}, U32.inc(n)))

@unsafe
def nc_head(+xs: List<&2, String>) -> String:
  match xs:
    case Nil{}: "0"
    case Con{+h, +t}: h

@unsafe
def nc_tail(+xs: List<&2, String>) -> List<&2, String>:
  match xs:
    case Nil{}: Nil{}
    case Con{+h, +t}: t

@unsafe
def nc_ctor_result(+x: N_Emitted) -> NC_Code:
  match x:
    case N_Emitted{+code, +word, +n}: NC_Code{code ++ ne_ret([word]), Nil{}, n, ""}

@unsafe
def nc_constructor(+name: String, +ws: List<&2, String>, +n: U32) -> NC_Code:
  nt_choose(NC_Code, String.eq(name, "Zero") || String.eq(name, "False"), u => nc_return("0", n), u =>
  nt_choose(NC_Code, String.eq(name, "True"), u => nc_return("1", n), u =>
  nt_choose(NC_Code, String.eq(name, "Succ"), u => nc_return("nat_chk(e, " ++ nc_head(ws) ++ " + 1)", n), u =>
  nt_choose(NC_Code, String.eq(name, "U32") || String.eq(name, "F32"), u => nc_return("term_word(e, " ++ nc_head(ws) ++ ")", n), u =>
  nt_choose(NC_Code, String.eq(name, "Chr"), u => nc_return(nc_head(ws), n), u =>
  nt_choose(NC_Code, String.eq(name, "ALeaf"), u => NC_Code{"Term init[1] = { " ++ nc_head(ws) ++ " };\n" ++ ne_ret(["blk_new(e, 1, 0, 0, 1, init)"]), Nil{}, n, ""}, u =>
  nt_choose(NC_Code, String.eq(name, "ANode"), u => nc_return("blk_node(e, " ++ nc_head(ws) ++ ", " ++ nc_head(nc_tail(ws)) ++ ")", n), u =>
  nc_ctor_result(ne_constructor(name, ws, False{}, n, True{})))))))))

@unsafe
def nc_lets(+book: List<&2, KDef>, +xs: List<&2, KTerm>, +env: List<&2, NC_Binding>, +n: U32) -> NC_Code:
  match xs:
    case Nil{}: nc_fail("empty native let", n)
    case Con{+h, Nil{}}: nc_lower(book, h, env, n)
    case Con{+h, +t}: nc_let(book, kid(h, 0), kt("NSeqLet", "", 0, 0, t), env, ix(h), n)

@unsafe
def nc_find_ctor(+book: List<&2, KDef>, +name: String) -> KDef:
  match book:
    case Nil{}: missing()
    case Con{+d, +rest}:
      nt_choose(KDef, String.eq(dn(d), name) && String.eq(dk(d), "Ctr"), u => d, u =>
        nt_choose(KDef, String.eq(dk(nc_find_ctor(dc(d), name)), "Absent"), u => nc_find_ctor(rest, name), u => nc_find_ctor(dc(d), name)))

@unsafe
def nc_field_count(+book: List<&2, KDef>, +name: String) -> U32:
  nt_choose(U32, String.eq(name, "Succ") || String.eq(name, "Chr") || String.eq(name, "U32") || String.eq(name, "F32"), u => 1, u =>
    nt_choose(U32, String.eq(name, "Zero") || String.eq(name, "True") || String.eq(name, "False"), u => 0, u => da(nc_find_ctor(book, nc_ctor_display(name)))))

@unsafe
def nc_condition(+name: String, +word: String) -> String:
  nt_choose(String, String.eq(name, "False"), u => "(!native_bool(" ++ word ++ "))", u =>
  nt_choose(String, String.eq(name, "True"), u => "native_bool(" ++ word ++ ")", u =>
  nt_choose(String, String.eq(name, "Zero"), u => "(" ++ word ++ " == 0)", u =>
  nt_choose(String, String.eq(name, "Succ"), u => "(" ++ word ++ " != 0)", u =>
  nt_choose(String, String.eq(name, "Chr") || String.eq(name, "U32") || String.eq(name, "F32"), u => "1", u =>
  nt_choose(String, String.eq(name, "ALeaf"), u => "(blk_cls(" ++ word ++ ") == 0)", u =>
  nt_choose(String, String.eq(name, "ANode"), u => "(blk_cls(" ++ word ++ ") != 0)", u =>
    "(term_aux(" ++ word ++ ") == " ++ nt_cid(name) ++ ")")))))))

@unsafe
def nc_field_word(+name: String, +word: String, +i: U32) -> String:
  nt_choose(String, String.eq(name, "Succ"), u => "(" ++ word ++ " - 1)", u =>
  nt_choose(String, String.eq(name, "Chr"), u => word, u =>
  nt_choose(String, String.eq(name, "U32") || String.eq(name, "F32"), u => "native_word(e, (u32)" ++ word ++ ")", u =>
  nt_choose(String, String.eq(name, "ALeaf"), u => "blk_read(e.mem, 1, term_loc(" ++ word ++ "), 0)", u =>
  nt_choose(String, String.eq(name, "ANode"), u => "blk_half(e, " ++ word ++ ", " ++ U32.show(i) ++ ")", u =>
    "e.mem[term_peek(e, " ++ word ++ ") + " ++ U32.show(i) ++ "]")))))

@unsafe
def nc_field_env(+name: String, +word: String, +count: U32, +i: U32, +n: U32) -> List<&2, NC_Binding>:
  nt_choose(List<&2, NC_Binding>, U32.is_eq(i, count), u => Nil{}, u =>
    Con{nc_binding(nc_id(U32.add(n, i))), nc_field_env(name, word, count, U32.inc(i), n)})

@unsafe
def nc_field_apps(+term: KTerm, +count: U32, +i: U32, +n: U32) -> KTerm:
  nt_choose(KTerm, U32.is_eq(i, count), u => term, u =>
    nc_field_apps(app(term, var("", nc_id(U32.add(n, i)))), count, U32.inc(i), n))

@unsafe
def nc_field_decls(+name: String, +word: String, +count: U32, +i: U32, +n: U32, +boxed: Bool) -> String:
  nt_choose(String, U32.is_eq(i, count), u => "", u =>
    "Term v_" ++ U32.show(nc_id(U32.add(n, i))) ++ " = " ++ nt_choose(String, boxed, u => "fields[" ++ U32.show(i) ++ "]", u => nc_field_word(name, word, i)) ++ ";\n" ++ nc_field_decls(name, word, count, U32.inc(i), n, boxed))

@unsafe
def nc_destructure(+name: String, +word: String, +count: U32, +n: U32) -> String:
  +boxed = Bool.not(String.eq(name, "Succ") || String.eq(name, "Zero") || String.eq(name, "True") || String.eq(name, "False") || String.eq(name, "Chr") || String.eq(name, "U32") || String.eq(name, "F32") || String.eq(name, "ALeaf") || String.eq(name, "ANode")) && U32.is_gt(count, 0)
  nt_choose(String, boxed,
    u => "Term fields[" ++ U32.show(count) ++ "];\n" ++ nt_choose(String, U32.is_eq(count, 1), u => "if (term_tag(" ++ word ++ ") == TAG_PAK) { fields[0] = term_loc(" ++ word ++ "); } else {\n", u => "") ++ "spare_free(e, cls_fit(" ++ U32.show(count) ++ "), ctr_take(e, " ++ word ++ ", " ++ U32.show(count) ++ ", fields));\n" ++ nt_choose(String, U32.is_eq(count, 1), u => "}\n", u => ""),
    u => "") ++ nc_field_decls(name, word, count, 0, n, boxed) ++ nt_choose(String, String.eq(name, "ALeaf"), u => "blk_free(e, " ++ word ++ ");\n", u => "")

law nc_match_apply_slow:
  for +book: List<&2, KDef>
  for +t: KTerm
  for +env: List<&2, NC_Binding>
  for +n: U32
  NC_Code

@unsafe
def nc_match_apply(+book: List<&2, KDef>, +t: KTerm, +env: List<&2, NC_Binding>, +n: U32) -> NC_Code:
  nt_choose(NC_Code, np_can_match(kid(t, 0)), u => np_match_apply(book, t, env, n), u => nc_match_apply_slow(book, t, env, n))

@unsafe
def nc_match_apply_slow(book, t, env, n):
  +mat = kid(t, 0)
  +arg = kid(t, 1)
  +word = nc_word(ix(arg), env)
  +count = nt_choose(U32, U32.is_eq(ix(mat), 0), u => nc_field_count(book, nm(mat)), u => U32.sub(ix(mat), 1))
  +hit = nc_lower(book, nc_field_apps(kid(mat, 0), count, 0, n), List.append(&2, NC_Binding, nc_remove_env(env, ix(arg)), nc_field_env(nm(mat), word, count, 0, n)), U32.add(n, count))
  +miss = nc_lower(book, app(kid(mat, 1), arg), env, nc_fresh(hit))
  +guard = nt_choose(String, String.eq(nm(mat), "Emit") || String.eq(nm(mat), "Halt"), u => "if (term_aux(" ++ word ++ ") != CID_EMIT && term_aux(" ++ word ++ ") != CID_HALT) { err_post(e.mem, ERR_TAGS); return 0; }\n", u => "")
  NC_Code{guard ++ "if (" ++ nc_condition(nm(mat), word) ++ ") {\n" ++ nc_destructure(nm(mat), word, count, n) ++ nc_body(hit) ++ "} else {\n" ++ nc_body(miss) ++ "}\n", nt_append(N_Segment, nc_segs(hit), nc_segs(miss)), nc_fresh(miss), nc_first_error(hit, miss)}

@unsafe
def nc_match(+book: List<&2, KDef>, +t: KTerm, +env: List<&2, NC_Binding>, +n: U32) -> NC_Code:
  nc_lambda(book, kt("Lam", "", nc_id(n), 1, [kt("NMatch", "", 0, 0, [t, var("", nc_id(n))])]), env, U32.inc(n))

@unsafe
def nc_primitive_name(k: String) -> String:
  String.to_lower(nt_clean(k))

law nc_array_known:
  for +k: String
  Bool

@unsafe
def nc_native_def(+d: KDef) -> Bool:
  +prim = nc_primitive_name(dn(d))
  db(d) && Bool.not(String.eq(tg(nc_unann(dv(d))), "Foreign")) && (Bool.not(String.eq(ni_find(prim, ni_templates()), "")) || nc_array_known(prim) || String.eq(prim, "nat_divmod"))

@unsafe
def nc_ref_name(+book: List<&2, KDef>, +name: String) -> String:
  nt_choose(String, nc_native_def(lookup(book, name)), u => "$native." ++ name, u => name)

@unsafe
def nc_primitive_arity(+k: String) -> U32:
  +fmt = ni_find(k, ni_templates())
  nt_choose(U32, String.eq(k, "array_set") || String.eq(k, "array_swap"), u => 3, u =>
  nt_choose(U32, String.eq(k, "array_new") || String.eq(k, "array_get") || String.eq(k, "nat_divmod"), u => 2, u =>
  nt_choose(U32, String.eq(fmt, nt_replace(fmt, "$1", "?")), u => 1, u => 2)))

@unsafe
def nc_prim_args(+n: U32, +i: U32) -> List<&2, KTerm>:
  nt_choose(List<&2, KTerm>, U32.is_eq(i, n), u => Nil{}, u => Con{var("", U32.add(4000000000, i)), nc_prim_args(n, U32.inc(i))})

@unsafe
def nc_prim_lambdas(+k: String, +n: U32, +i: U32) -> KTerm:
  nt_choose(KTerm, U32.is_eq(i, n), u => kt("NOp", k, 0, 0, nc_prim_args(n, 0)), u => kt("Lam", "", U32.add(4000000000, i), 1, [nc_prim_lambdas(k, n, U32.inc(i))]))

@unsafe
def nc_primitive_body(+k: String) -> KTerm:
  nc_prim_lambdas(k, nc_primitive_arity(k), 0)

@unsafe
def nc_intrinsic(+k: String, +ws: List<&2, String>, +n: U32) -> NC_Code:
  nt_choose(NC_Code, nc_array_known(k), u => nc_array(k, ws, n), u =>
  nt_choose(NC_Code, String.eq(k, "nat_divmod"), u => nc_ctor_result(ne_constructor("Tuple", ["(" ++ nc_head(nc_tail(ws)) ++ " == 0 ? 0 : " ++ nc_head(ws) ++ " / " ++ nc_head(nc_tail(ws)) ++ ")", "(" ++ nc_head(nc_tail(ws)) ++ " == 0 ? " ++ nc_head(ws) ++ " : " ++ nc_head(ws) ++ " % " ++ nc_head(nc_tail(ws)) ++ ")"], False{}, n, True{})), u =>
  nt_choose(NC_Code, String.eq(k, "u32_cmp") || String.eq(k, "nat_cmp"), u => NC_Code{"Term cmp = " ++ ni_emit(k, ws) ++ ";\n" ++ ne_ret(["term_pak(cmp == 0 ? CID_LT : cmp == 1 ? CID_EQ : CID_GT, 0)"]), Nil{}, n, ""}, u =>
    nc_return(ni_emit(k, ws), n))))

@unsafe
def nc_apply_code(+ws: List<&2, String>, +n: U32) -> NC_Code:
  NC_Code{ "{ Term fn = " ++ nc_head(ws) ++ "; Term arg = " ++ nc_head(nc_tail(ws)) ++ ";\n"
    ++ "Fid f = (Fid)term_aux(fn);\n"
    ++ "if (!seq && fid_bangs(f)) {\n  u32 war = fid_arity(f) - 1;\n  Loc src = term_loc(fn);\n  Loc dst = task_node(e, f, WL_CONT, WL_IDX, 0);\n  for (u32 j = 0; j < war; ++j) e.mem[dst + j] = e.mem[src + j];\n  e.mem[dst + war] = arg;\n  spare_free(e, cls_fit(war), src);\n  return term_tsk(f, dst);\n}\nr0 = fn; r1 = arg; WL_JMP(BEND_CLO_APPLY);\n}\n", Nil{}, n, ""}

@unsafe
def nc_word_literal(+t: KTerm, +bit: U32, +value: U32) -> NC_Literal:
  nt_choose(NC_Literal, String.eq(tg(t), "Ctr") && String.eq(nm(t), "WNil"), u => NC_Literal{True{}, value}, u =>
  nt_choose(NC_Literal, String.eq(tg(t), "Ctr") && String.eq(nm(t), "WCon") && U32.is_lt(bit, 32) && String.eq(tg(kid(t, 0)), "Ctr") && (String.eq(nm(kid(t, 0)), "True") || String.eq(nm(kid(t, 0)), "False")),
    u => nc_word_literal(kid(t, 1), U32.inc(bit), U32.or(value, nt_choose(U32, String.eq(nm(kid(t, 0)), "True"), u => U32.shln(1, U32.to_nat(bit)), u => 0))),
    u => NC_Literal{False{}, 0}))

@unsafe
def nc_nat_literal(+t: KTerm, +value: U32) -> NC_Literal:
  nt_choose(NC_Literal, core_nat(t), u => nt_choose(NC_Literal, U32.is_le(qt(t), U32.sub(4294967295, value)), u => NC_Literal{True{}, U32.add(value, qt(t))}, u => NC_Literal{False{}, 0}), u =>
  nt_choose(NC_Literal, String.eq(tg(t), "Ctr") && String.eq(nm(t), "Zero"), u => NC_Literal{True{}, value}, u =>
    nt_choose(NC_Literal, String.eq(tg(t), "Ctr") && String.eq(nm(t), "Succ"), u => nc_nat_literal(kid(t, 0), U32.inc(value)), u => NC_Literal{False{}, 0})))

@unsafe
def nc_literal(+t: KTerm) -> NC_Literal:
  nt_choose(NC_Literal, String.eq(nm(t), "U32") || String.eq(nm(t), "F32"), u => nc_word_literal(kid(t, 0), 0, 0), u => nc_nat_literal(t, 0))

law nc_compact:
  for +t: KTerm
  KTerm
@unsafe
def nc_compact_list(
  +ts: List<&2, KTerm>,
) -> List<&2, KTerm>:
  match ts:
    case Nil{}: Nil{}
    case Con{h, rest}: Con{nc_compact(h), nc_compact_list(rest)}

law nc_compact_succ:
  for +t: KTerm
  for +count: U32
  KTerm

@unsafe
def nc_compact_ctor(+t: KTerm, lit: NC_Literal) -> KTerm:
  match lit:
    case NC_Literal{valid, value}:
      nt_choose(KTerm, valid, u => kt("NWord", U32.show(value), 0, 0, Nil{}), u => nt_choose(KTerm, String.eq(nm(t), "Succ") && U32.is_eq(terms_len(ks(t)), 1), u => nc_compact_succ(kid(t, 0), 1), u => kt(tg(t), nm(t), ix(t), qt(t), nc_compact_list(ks(t)))))

@unsafe
def nc_compact(t):
  kc(KTerm, core_nat(t), u => kt("NWord", U32.show(qt(t)), 0, 0, Nil{}), u =>
  nt_choose(KTerm, String.eq(tg(t), "Ctr"), u => nc_compact_ctor(t, nc_literal(t)), u => kt(tg(t), nm(t), ix(t), qt(t), nc_compact_list(ks(t)))))

@unsafe
def nc_lower_ctor(+book: List<&2, KDef>, +t: KTerm, +env: List<&2, NC_Binding>, +n: U32, lit: NC_Literal) -> NC_Code:
  match lit:
    case NC_Literal{+valid, +value}:
      nt_choose(NC_Code, valid, u => nc_return(U32.show(value) ++ "ull", n), u => nc_lower(book, nc_sequence("NCtr", nm(t), ks(t), Nil{}, n), env, U32.add(n, terms_len(ks(t)))))

@unsafe
def nc_lower_live(book, t, env, n):
  +tag = tg(t)
  nt_choose(NC_Code, String.eq(tag, "NWord"), u => nc_return(nm(t) ++ "ull", n), u =>
  nt_choose(NC_Code, String.eq(tag, "Var"), u => nt_choose(NC_Code, String.eq(nc_word(ix(t), env), "NATIVE_UNBOUND_VARIABLE"), u => nc_fail("native unbound variable " ++ U32.show(ix(t)), n), u => nc_return(nc_word(ix(t), env), n)), u =>
  nt_choose(NC_Code, String.eq(tag, "Ref"), u => NC_Code{ne_jump(Nil{}, nc_ref_name(book, nm(t))), Nil{}, n, ""}, u =>
  nt_choose(NC_Code, String.eq(tag, "Ann") || String.eq(tag, "Loc") || String.eq(tag, "Src") || String.eq(tag, "Cut") || String.eq(tag, "Slf") || String.eq(tag, "Ins"), u => nc_lower(book, kid(t, 0), env, n), u =>
  nt_choose(NC_Code, String.eq(tag, "Lam"), u => nc_lambda(book, t, env, n), u =>
  nt_choose(NC_Code, String.eq(tag, "App"), u => nd_app(book, t, env, n), u =>
  nt_choose(NC_Code, String.eq(tag, "Let"), u => nt_choose(NC_Code, U32.is_gt(terms_len(ks(t)), 2), u => nc_parallel(book, ks(t), env, n), u => nc_lets(book, ks(t), env, n)), u =>
  nt_choose(NC_Code, String.eq(tag, "NSeqLet"), u => nc_lets(book, ks(t), env, n), u =>
  nt_choose(NC_Code, String.eq(tag, "NNatAdd"), u => nc_lower(book, nc_sequence("NNatSum", nm(t), ks(t), Nil{}, n), env, U32.inc(n)), u =>
  nt_choose(NC_Code, String.eq(tag, "NNatSum"), u => nc_return("nat_chk(e, nat_chk(e, " ++ nc_head(nc_values(ks(t), env)) ++ " + 1) + " ++ nm(t) ++ "ull)", n), u =>
  nt_choose(NC_Code, String.eq(tag, "Ctr"), u => nc_lower_ctor(book, t, env, n, nc_literal(t)), u =>
  nt_choose(NC_Code, String.eq(tag, "NCtr"), u => nc_constructor(nm(t), nc_values(ks(t), env), n), u =>
  nt_choose(NC_Code, String.eq(tag, "NApply"), u => nc_apply_code(nc_values(ks(t), env), n), u =>
  nt_choose(NC_Code, String.eq(tag, "NCall"), u => NC_Code{ne_jump(nc_values(ks(t), env), nm(t)), Nil{}, n, ""}, u =>
  nt_choose(NC_Code, String.eq(tag, "Rfl") || String.eq(tag, "Typ") || String.eq(tag, "All") || String.eq(tag, "Qua") || String.eq(tag, "ADT") || String.eq(tag, "Eql"), u => nc_return("0", n), u =>
  nt_choose(NC_Code, String.eq(tag, "Mat"), u => nc_match(book, t, env, n), u =>
  nt_choose(NC_Code, String.eq(tag, "NMatch"), u => nc_match_apply(book, t, env, n), u =>
  nt_choose(NC_Code, String.eq(tag, "NOp"), u => nc_intrinsic(nm(t), nc_values(ks(t), env), n), u =>
  nt_choose(NC_Code, String.eq(tag, "Efq"), u => NC_Code{"err_post(e.mem, ERR_FIDS); return 0;\n", Nil{}, n, ""}, u =>
  nt_choose(NC_Code, String.eq(tag, "Rwt"), u => nc_lower(book, kid(t, 2), env, n), u =>
  nc_fail("native lowering does not support core node " ++ tag, n)))))))))))))))))))))

# Typed erasure renames user-owned constructors; this pass sees native Succ only.
# Keep the first checked increment: even a malformed foreign U64 tail retains
# its original wrapping/error behavior before the bounded remaining offset.
@unsafe
def nc_compact_succ(t, count):
  nt_choose(KTerm, U32.is_eq(count, 0), u => nc_compact(t), u =>
  nt_choose(KTerm, String.eq(tg(t), "Ctr") && String.eq(nm(t), "Succ") && U32.is_eq(terms_len(ks(t)), 1) && U32.is_lt(count, 4294967295),
    u => nc_compact_succ(kid(t, 0), U32.inc(count)),
    u => nt_choose(KTerm, U32.is_eq(count, 1), u => kt("Ctr", "Succ", 0, 0, [nc_compact(t)]), u => kt("NNatAdd", U32.show(U32.sub(count, 1)), 0, 0, [nc_compact(t)]))))
