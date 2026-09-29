law nc_context_index:
  for annotated: List<&2, KDef>
  List<&2, KDef>

law nc_context_pick:
  for +original: KDef
  for +annotated: KDef
  KDef

type NC_Result is Data:
  NC_Result{+source: String, +error: String}

type NC_Book is Data:
  NC_Book{+segments: List<&2, N_Segment>, +fresh: U32, +error: String}

law nc_unann:
  for +t: KTerm
  KTerm

law nc_constructors:
  for +book: List<&2, KDef>
  for +ds: List<&2, KDef>
  List<&2, N_Constructor>

law nc_refs:
  for +t: KTerm
  List<&2, String>

law nc_compile_defs:
  for +book: List<&2, KDef>
  for +todo: List<&2, String>
  for +done: List<&2, String>
  for +n: U32
  for +bangs: List<&2, String>
  NC_Book

law nc_term_fork:
  for +t: KTerm
  Bool

@unsafe
def nc_refs_go(todo: List<&2, KTerm>, +acc: List<&2, String>) -> List<&2, String>:
  match todo:
    case Nil{}: nt_reverse(String, acc, Nil{})
    case Con{+h, +rest}:
      nc_refs_go(nt_append(KTerm, ks(h), rest), nt_choose(List<&2, String>, String.eq(tg(h), "Ref"), u => Con{nm(h), acc}, u => acc))

@unsafe
def nc_refs(t):
  nc_refs_go([t], Nil{})

@unsafe
def nc_foreign_tel(+book: List<&2, KDef>, +ty: KTerm, +name: String, +args: List<&2, KTerm>, +n: U32) -> KTerm:
  +tel = wnf(book, ty)
  nt_choose(KTerm, String.eq(tg(tel), "All"),
    u => nt_choose(KTerm, U32.is_eq(qt(tel), 0),
      u => nc_foreign_tel(book, subst(kid(tel, 1), ix(tel), atom("Typ")), name, args, U32.inc(n)),
      u => k_lam("", nc_id(n), 1, [nc_foreign_tel(book, subst(kid(tel, 1), ix(tel), var("", nc_id(n))), name, List.append(&2, KTerm, args, [var("", nc_id(n))]), U32.inc(n))], 0, 0, False{})),
    u => kt("NCtr", name, 0, 0, args))

@unsafe
def nc_unann(t):
  nt_choose(KTerm, String.eq(tg(t), "Ann"), u => nc_unann(kid(t, 0)), u => t)

@unsafe
def nc_foreign(+d: KDef) -> Bool:
  String.eq(tg(nc_unann(dv(d))), "Foreign") || String.eq(tg(nc_unann(dv(d))), "Absent")

@unsafe
def nc_definition(+book: List<&2, KDef>, +d: KDef, +n: U32) -> KTerm:
  +prim = nc_primitive_name(dn(d))
  nt_choose(KTerm, nc_native_def(d),
    u => nc_primitive_body(prim),
    u => nt_choose(KTerm, nc_foreign(d),
      u => nc_foreign_tel(book, dt(d), dn(d), Nil{}, n),
      u => nc_erase(book, dv(d))))

@unsafe
def nc_call_head(+t: KTerm) -> KTerm:
  nt_choose(KTerm, String.eq(tg(t), "App"), u => nc_call_head(kid(t, 0)), u => t)

@unsafe
def nc_terms_fork(
  +ts: List<&2, KTerm>,
) -> Bool:
  match ts:
    case Nil{}: False{}
    case Con{+h, +rest}:
      nt_choose(Bool, (String.eq(tg(h), "Let") && U32.is_gt(terms_len(ks(h)), 2)) || (String.eq(tg(h), "App") && String.eq(tg(nc_call_head(h)), "Var")),
        u => True{}, u => nc_terms_fork(nt_append(KTerm, ks(h), rest)))

@unsafe
def nc_term_fork(t):
  nc_terms_fork([t])

@unsafe
def nc_mapped_refs(+book: List<&2, KDef>, refs: List<&2, String>) -> List<&2, String>:
  match refs:
    case Nil{}: Nil{}
    case Con{h, rest}: Con{nc_ref_name(book, h), nc_mapped_refs(book, rest)}

@unsafe
def nc_mark_segments_go(ss: List<&2, N_Segment>, +bang: Bool, +forked: Bool, +calls: List<&2, String>, acc: List<&2, N_Segment>) -> List<&2, N_Segment>:
  match ss:
    case Nil{}: nt_reverse(N_Segment, acc, Nil{})
    case Con{N_Segment{k, ps, r, f, b, +refs, host, spin, fork, old}, rest}:
      nc_mark_segments_go(rest, bang, forked, calls, Con{N_Segment{k, ps, r, f, b, nt_choose(List<&2, String>, nb_contains(refs, "$local"), u => refs, u => calls), host, spin, nt_choose(Bool, nb_contains(refs, "$local"), u => fork, u => forked), bang}, acc})

@unsafe
def nc_mark_segments(ss: List<&2, N_Segment>, +bang: Bool, +forked: Bool, +calls: List<&2, String>) -> List<&2, N_Segment>:
  nc_mark_segments_go(ss, bang, forked, calls, Nil{})

@unsafe
def nc_mark_code(c: NC_Code, bang: Bool, forked: Bool, calls: List<&2, String>) -> NC_Code:
  match c:
    case NC_Code{body, ss, n, err}: NC_Code{body, nc_mark_segments(ss, bang, forked, calls), n, err}

@unsafe
def nc_append_book(+code: NC_Code, name: String, calls: List<&2, String>, forked: Bool, rest: NC_Book) -> NC_Book:
  match rest:
    case NC_Book{segs, fresh, +err}:
      NC_Book{Con{N_Segment{name, Nil{}, 1, N_Direct{}, nc_body(code), calls, False{}, False{}, forked, False{}}, nt_append(N_Segment, nc_segs(code), segs)}, fresh, nt_choose(String, String.eq(nc_error(code), ""), u => err, u => nc_error(code))}

@unsafe
def nc_compile_def(+book: List<&2, KDef>, +name: String, +todo: List<&2, String>, +done: List<&2, String>, +n: U32, +bangs: List<&2, String>) -> NC_Book:
  +d = lookup(book, name)
  +body = nc_compact(nc_definition(book, d, n))
  +refs = nc_refs(body)
  +calls = nc_mapped_refs(book, refs)
  +forked = nc_term_fork(body)
  +code = nc_mark_code(nd_extend(book, body, nc_lower(book, body, Nil{}, U32.add(n, 1024)), name), nb_contains(bangs, name), forked, calls)
  nt_choose(NC_Book, String.eq(dk(d), "Absent"), u => NC_Book{Nil{}, n, "native definition not found: " ++ name}, u =>
    nc_append_book(code, nc_ref_name(book, name), calls, forked, nc_compile_defs(book, List.append(&2, String, refs, todo), Con{name, done}, nc_fresh(code), bangs)))

@unsafe
def nc_compile_defs(book, todo, done, n, bangs):
  match todo:
    case Nil{}: NC_Book{Nil{}, n, ""}
    case Con{name, rest}:
      nt_choose(NC_Book, nb_contains(done, name), u => nc_compile_defs(book, rest, done, n, bangs), u => nc_compile_def(book, name, rest, done, n, bangs))

@unsafe
def nc_skip_tel(+book: List<&2, KDef>, +tel: KTerm, +n: U32) -> KTerm:
  nt_choose(KTerm, U32.is_eq(n, 0), u => tel, u => nc_skip_tel(book, kid(wnf(book, tel), 1), U32.sub(n, 1)))

@unsafe
def nc_ctor_specs(+book: List<&2, KDef>, cs: List<&2, KDef>, +params: U32) -> List<&2, N_Constructor>:
  match cs:
    case Nil{}: Nil{}
    case Con{+c, rest}: Con{N_Constructor{nc_ctor_identity(book, dn(c)), nc_live_count(book, nc_skip_tel(book, dt(c), params), da(c)), True{}}, nc_ctor_specs(book, rest, params)}

@unsafe
def nc_all_args(+book: List<&2, KDef>, +ty: KTerm) -> U32:
  +tel = wnf(book, ty)
  nt_choose(U32, String.eq(tg(tel), "All"), u => U32.add(nt_bool(Bool.not(U32.is_eq(qt(tel), 0))), nc_all_args(book, kid(tel, 1))), u => 0)

@unsafe
def nc_constructors(book, ds):
  match ds:
    case Nil{}: Nil{}
    case Con{+d, +rest}:
      nt_choose(List<&2, N_Constructor>, String.eq(dk(d), "ADT"),
        u => List.append(&2, N_Constructor, nc_ctor_specs(book, dc(d), da(d)), nc_constructors(book, rest)),
        u => nt_choose(List<&2, N_Constructor>, String.eq(dk(d), "Def") && nc_foreign(d),
          u => Con{N_Constructor{dn(d), nc_all_args(book, dt(d)), True{}}, nc_constructors(book, rest)},
          u => nc_constructors(book, rest)))

@unsafe
def nc_default_ctors() -> List<&2, N_Constructor>:
  [N_Constructor{"Tuple", 2, True{}}, N_Constructor{"SNil", 0, True{}}, N_Constructor{"SCon", 2, True{}}, N_Constructor{"WCon", 2, True{}}, N_Constructor{"WNil", 0, True{}}, N_Constructor{"Emit", 1, True{}}, N_Constructor{"Halt", 2, True{}}, N_Constructor{"Done", 1, True{}}, N_Constructor{"Fail", 1, True{}}, N_Constructor{"Some", 1, True{}}, N_Constructor{"None", 0, True{}}, N_Constructor{"True", 0, True{}}, N_Constructor{"False", 0, True{}}, N_Constructor{"Unit", 0, True{}}, N_Constructor{"LT", 0, True{}}, N_Constructor{"EQ", 0, True{}}, N_Constructor{"GT", 0, True{}}]

@unsafe
def nc_has_ctor(cs: List<&2, N_Constructor>, +key: String) -> Bool:
  match cs:
    case Nil{}: False{}
    case Con{N_Constructor{k, a, h}, rest}: String.eq(k, key) || nc_has_ctor(rest, key)

@unsafe
def nc_add_ctors(cs: List<&2, N_Constructor>, +acc: List<&2, N_Constructor>) -> List<&2, N_Constructor>:
  match cs:
    case Nil{}: acc
    case Con{N_Constructor{+k, +a, +h}, rest}: nc_add_ctors(rest, nt_choose(List<&2, N_Constructor>, nc_has_ctor(acc, k), u => acc, u => List.append(&2, N_Constructor, acc, [N_Constructor{k, a, h}])))

@unsafe
def nc_show(+cells: String) -> String:
  "#if !DEVICE\nstatic const u32 SHOW_DESC[] = { " ++ cells ++ " };\nstatic const char* SHOW_NAMES[] = {\"False\", \"True\", \"Unit\"};\n#endif\n"

@unsafe
def nc_is_io(+book: List<&2, KDef>, +ty: KTerm) -> Bool:
  +io = lookup(book, "IO")
  +shadow = book_put(book, KDef{dn(io), dk(io), da(io), dx(io), dt(io), atom("Absent"), dc(io), db(io), du(io)})
  +head = wnf(shadow, ty)
  String.eq(dk(io), "Def") && db(io) && String.eq(tg(head), "App") && String.eq(tg(kid(head, 0)), "Ref") && String.eq(nm(kid(head, 0)), "IO")

@unsafe
def nc_helpers() -> String:
  "INLINE bool native_bool(Term t) { return t == 1 || (term_tag(t) == TAG_PAK && term_aux(t) == CID_TRUE); }\nINLINE Term native_word(Env e, u32 x) {\n  Term w = term_pak(CID_WNIL, 0);\n  for (u32 i = 32; i > 0; i--) {\n    Loc p = heap_alloc(e, 1);\n    e.mem[p] = (x >> (i - 1)) & 1;\n    e.mem[p + 1] = rfc_seal(e, w);\n    w = term_ctr(CID_WCON, p);\n  }\n  return w;\n}\n"

@unsafe
def nc_with_show(+ss: List<&2, N_Segment>, +cs: List<&2, N_Constructor>, runtime: String, requests: String, pure: Bool, d: NC_Show) -> NC_Result:
  match d:
    case NC_Show{+src, +err}: nt_choose(NC_Result, String.eq(nv_first(err, nv_program(ss, cs)), ""), u => NC_Result{ne_program(runtime, N_Program{ss, cs, Nil{}, requests, nc_helpers(), src, pure}), ""}, u => NC_Result{"", nv_first(err, nv_program(ss, cs))})

@unsafe
def nc_finish(+book: List<&2, KDef>, +runtime: String, +requests: String, compiled: NC_Book) -> NC_Result:
  match compiled:
    case NC_Book{+ss, n, +error}:
      +ty = dt(lookup(book, "main"))
      +pure = Bool.not(nc_is_io(book, ty))
      +cs = nc_add_ctors(nc_default_ctors(), nc_constructors(book, book))
      nt_choose(NC_Result, Bool.not(String.eq(error, "")), u => NC_Result{"", error}, u =>
        nc_with_show(ss, cs, runtime, requests, pure, nt_choose(NC_Show, pure, u => nc_show_program(book, ty, cs), u => NC_Show{nc_show("0"), ""})))

law nc_bangs_term:
  for +t: KTerm
  List<&2, String>

@unsafe
def nc_bangs_terms(
  +ts: List<&2, KTerm>,
) -> List<&2, String>:
  match ts:
    case Nil{}: Nil{}
    case Con{h, rest}: List.append(&2, String, nc_bangs_term(h), nc_bangs_terms(rest))

@unsafe
def nc_bangs_term(t):
  nt_choose(List<&2, String>, String.eq(tg(t), "Var"), u => Nil{}, u => nt_choose(List<&2, String>, String.eq(tg(t), "Ref") && U32.is_eq(qt(t), 3), u => [nm(t)], u => nt_choose(List<&2, String>, String.eq(tg(t), "Ann"), u => nc_bangs_term(kid(t, 0)), u => nc_bangs_terms(ks(t)))))

@unsafe
def nc_bangs_book(book: List<&2, KDef>) -> List<&2, String>:
  match book:
    case Nil{}: Nil{}
    case Con{d, rest}: List.append(&2, String, nc_bangs_term(dv(d)), nc_bangs_book(rest))

@unsafe
def nc_compile(+book: List<&2, KDef>, runtime: String, requests: String) -> NC_Result:
  +main = lookup(book, "main")
  +owned = nv_owned(book)
  nt_choose(NC_Result, Bool.not(String.eq(owned, "")), u => NC_Result{"", owned}, u =>
  nt_choose(NC_Result, Bool.not(String.eq(dk(main), "Def")) || String.eq(tg(nc_unann(dv(main))), "Absent"), u => NC_Result{"", "no main to run"}, u =>
  nt_choose(NC_Result, nc_is_io(book, dt(main)) && String.eq(tg(nc_unann(dv(main))), "Foreign"), u => NC_Result{"", "main must be a filled def: a foreign main cannot anchor IO"}, u =>
  nt_choose(NC_Result, U32.is_ge(norm_max_book(book), 4000000000), u => NC_Result{"", "native source binder IDs overlap the compiler temporary range"}, u => nc_finish(book, runtime, requests, nc_compile_defs(book, ["main"], Nil{}, 0, nc_bangs_book(book)))))))

@unsafe
def nc_live_names(+book: List<&2, KDef>, todo: List<&2, String>, +done: List<&2, String>) -> List<&2, String>:
  match todo:
    case Nil{}: done
    case Con{+name, +rest}:
      nt_choose(List<&2, String>, nb_contains(done, name), u => nc_live_names(book, rest, done), u => nc_live_names(book, List.append(&2, String, nc_refs(nc_definition(book, lookup(book, name), 0)), rest), Con{name, done}))

@unsafe
def nc_c_paths(paths: List<&2, KTerm>) -> List<&2, String>:
  match paths:
    case Nil{}: Nil{}
    case Con{+h, +rest}: nt_choose(List<&2, String>, String.ends_with(nm(h), ".c"), u => Con{nm(h), nc_c_paths(rest)}, u => nc_c_paths(rest))

@unsafe
def nc_paths_of(+book: List<&2, KDef>, names: List<&2, String>) -> List<&2, String>:
  match names:
    case Nil{}: Nil{}
    case Con{name, rest}: List.append(&2, String, nc_c_paths(ks(nc_unann(dv(lookup(book, name))))), nc_paths_of(book, rest))

@unsafe
def nc_foreign_paths(+book: List<&2, KDef>) -> List<&2, String>:
  nc_paths_of(book, nc_live_names(book, ["main"], Nil{}))

# Selective annotation keeps all original type-level definitions in scope.
# The host asks reach_book for main's closure, annotates it in the original
# context, and replaces only those entries before native emission.
@unsafe
def nc_annotation_stops(book: List<&2, KDef>) -> List<&2, String>:
  match book:
    case Nil{}: Nil{}
    case Con{+d, +rest}:
      nt_choose(List<&2, String>, nc_native_def(d),
        u => Con{dn(d), nc_annotation_stops(rest)},
        u => nc_annotation_stops(rest))

@unsafe
def nc_context_defs(book: List<&2, KDef>, +annotated: List<&2, KDef>) -> List<&2, KDef>:
  match book:
    case Nil{}: Nil{}
    case Con{+d, +rest}:
      nt_choose(List<&2, KDef>, String.eq(dk(d), "BookCache"),
        u => nc_context_defs(rest, annotated),
        u => Con{nc_context_pick(d, lookup(annotated, dn(d))), nc_context_defs(rest, annotated)})

@unsafe
def nc_annotated_context(+book: List<&2, KDef>, +annotated: List<&2, KDef>) -> List<&2, KDef>:
  +merged = nc_context_defs(book, nc_context_index(annotated))
  book_cached(merged, norm_max_book(merged))

# Build an immutable first-match index once for plain annotation lists.
# A cache sentinel anywhere changes lookup semantics, so retain that input.
@unsafe
def nc_context_index(annotated):
  match annotated:
    case Nil{}: Nil{}
    case Con{+head, +rest}:
      nt_choose(List<&2, KDef>, nc_context_has_cache(Con{head, rest}), u => Con{head, rest}, u => book_cached(Con{head, rest}, 0))

@unsafe
def nc_context_pick(original, annotated):
  nt_choose(KDef, String.eq(dk(annotated), "Absent"), u => original, u => annotated)

law nc_context_has_cache:
  for annotated: List<&2, KDef>
  Bool

@unsafe
def nc_context_has_cache(annotated):
  match annotated:
    case Nil{}: False{}
    case Con{head, rest}:
      nt_choose(Bool, String.eq(dk(head), "BookCache"), u => True{}, u => nc_context_has_cache(rest))
