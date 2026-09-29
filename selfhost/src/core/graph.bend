import Base

# Pure graph reduction for strong normalization. GCell nodes reference a
# persistent memo heap; their argument payloads are never copied by substitution.
# Every GCell is forced before the public normal form is returned.
type GHeap is Data:
  GEmpty{}
  GNode{+value: KTerm, +left: GHeap, +right: GHeap}

type GState is Data:
  GState{+heap: GHeap, +next: U32}

type GResult is Data:
  GResult{+state: GState, +term: KTerm}

type GTerms is Data:
  GTerms{+state: GState, +terms: List<&2, KTerm>}

type GFrame is Data:
  GFill{+id: U32, +args: List<&2, KTerm>, +pending: U32, +fallback: KTerm}
  GMatch{+arm: KTerm, +raw: KTerm, +args: List<&2, KTerm>, +pending: U32, +fallback: KTerm}
  GMinA{+other: KTerm, +args: List<&2, KTerm>}
  GMinB{+other: KTerm, +args: List<&2, KTerm>}
  GRewrite{+original: KTerm, +args: List<&2, KTerm>, +pending: U32, +fallback: KTerm}

law g_put_node:
  for +old: KTerm
  for +left: GHeap
  for +right: GHeap
  for +id: U32
  for +value: KTerm
  GHeap

law g_shared_term:
  for +rest: List<&2, KTerm>
  for +done: List<&2, KTerm>
  for +r: GResult
  GTerms

law g_shared_head:
  for +t: KTerm
  for +r: GTerms
  GResult

law g_eval:
  for +book: List<&2, KDef>
  for +st: GState
  for +t: KTerm
  for +args: List<&2, KTerm>
  for +pending: U32
  for +fallback: KTerm
  for +stack: List<&2, GFrame>
  GResult

law g_cell:
  for +book: List<&2, KDef>
  for +st: GState
  for +t: KTerm
  for +args: List<&2, KTerm>
  for +pending: U32
  for +fallback: KTerm
  for +stack: List<&2, GFrame>
  for +cell: KTerm
  GResult

law g_app:
  for +book: List<&2, KDef>
  for +fn: KTerm
  for +args: List<&2, KTerm>
  for +pending: U32
  for +fallback: KTerm
  for +stack: List<&2, GFrame>
  for +r: GResult
  GResult

law g_ref:
  for +book: List<&2, KDef>
  for +st: GState
  for +t: KTerm
  for +args: List<&2, KTerm>
  for +stack: List<&2, GFrame>
  for +d: KDef
  GResult

law g_args:
  for +book: List<&2, KDef>
  for +st: GState
  for +t: KTerm
  for +args: List<&2, KTerm>
  for +pending: U32
  for +fallback: KTerm
  for +stack: List<&2, GFrame>
  GResult

law g_return:
  for +book: List<&2, KDef>
  for +st: GState
  for +t: KTerm
  for +stack: List<&2, GFrame>
  GResult

law g_resume:
  for +book: List<&2, KDef>
  for +st: GState
  for +t: KTerm
  for +frame: GFrame
  for +stack: List<&2, GFrame>
  GResult

law g_filled:
  for +book: List<&2, KDef>
  for +id: U32
  for +args: List<&2, KTerm>
  for +pending: U32
  for +fallback: KTerm
  for +stack: List<&2, GFrame>
  for +r: GResult
  GResult

law g_min_left:
  for +book: List<&2, KDef>
  for +st: GState
  for +a: KTerm
  for +b: KTerm
  for +args: List<&2, KTerm>
  for +stack: List<&2, GFrame>
  GResult

law g_match:
  for +book: List<&2, KDef>
  for +st: GState
  for +arm: KTerm
  for +original: KTerm
  for +raw: KTerm
  for +x: KTerm
  for +args: List<&2, KTerm>
  for +pending: U32
  for +fallback: KTerm
  for +stack: List<&2, GFrame>
  GResult

law g_let:
  for +book: List<&2, KDef>
  for +st: GState
  for +ts: List<&2, KTerm>
  for +bindings: List<&2, KTerm>
  for +args: List<&2, KTerm>
  for +pending: U32
  for +fallback: KTerm
  for +stack: List<&2, GFrame>
  GResult

law g_let_shared:
  for +book: List<&2, KDef>
  for +h: KTerm
  for +rest: List<&2, KTerm>
  for +bindings: List<&2, KTerm>
  for +args: List<&2, KTerm>
  for +pending: U32
  for +fallback: KTerm
  for +stack: List<&2, GFrame>
  for +r: GResult
  GResult

law g_let_sub:
  for +t: KTerm
  for +bindings: List<&2, KTerm>
  KTerm

law graph_strong:
  for +book: List<&2, KDef>
  for +t: KTerm
  KTerm

law g_snf_head:
  for +book: List<&2, KDef>
  for +stack: List<&2, KNormFrame>
  for +fresh: U32
  for +r: GResult
  KTerm

law g_snf_open:
  for +book: List<&2, KDef>
  for +st: GState
  for +t: KTerm
  for +stack: List<&2, KNormFrame>
  for +fresh: U32
  KTerm

law g_snf_children:
  for +book: List<&2, KDef>
  for +st: GState
  for +parent: KTerm
  for +done: List<&2, KTerm>
  for +todo: List<&2, KTerm>
  for +stack: List<&2, KNormFrame>
  for +fresh: U32
  KTerm

law g_snf_return:
  for +book: List<&2, KDef>
  for +st: GState
  for +t: KTerm
  for +stack: List<&2, KNormFrame>
  for +fresh: U32
  KTerm

@unsafe
def g_heap(
  +st: GState,
) -> GHeap:
  match st:
    case GState{heap, next}:
      heap

@unsafe
def g_next(
  +st: GState,
) -> U32:
  match st:
    case GState{heap, next}:
      next

@unsafe
def g_state(
  +r: GResult,
) -> GState:
  match r:
    case GResult{state, term}:
      state

@unsafe
def g_term(
  +r: GResult,
) -> KTerm:
  match r:
    case GResult{state, term}:
      term

@unsafe
def g_states(
  +r: GTerms,
) -> GState:
  match r:
    case GTerms{state, terms}:
      state

@unsafe
def g_terms(
  +r: GTerms,
) -> List<&2, KTerm>:
  match r:
    case GTerms{state, terms}:
      terms

@unsafe
def g_get(
  +heap: GHeap,
  +id: U32,
) -> KTerm:
  match heap:
    case GEmpty{}:
      atom("Absent")
    case GNode{value, left, right}:
      kc(KTerm, U32.is_eq(id, 0), u => value, u => kc(KTerm, U32.is_eq(U32.and(id, 1), 0), u => g_get(left, U32.shr(id)), u => g_get(right, U32.shr(id))))

@unsafe
def g_put(
  +heap: GHeap,
  +id: U32,
  +value: KTerm,
) -> GHeap:
  match heap:
    case GEmpty{}:
      g_put_node(atom("Absent"), GEmpty{}, GEmpty{}, id, value)
    case GNode{old, left, right}:
      g_put_node(old, left, right, id, value)

@unsafe
def g_put_node(old, left, right, id, value):
  kc(GHeap, U32.is_eq(id, 0), u => GNode{value, left, right}, u => kc(GHeap, U32.is_eq(U32.and(id, 1), 0), u => GNode{old, g_put(left, U32.shr(id), value), right}, u => GNode{old, left, g_put(right, U32.shr(id), value)}))

@unsafe
def g_share(
  +st: GState,
  +t: KTerm,
) -> GResult:
  kc(GResult, String.eq(tg(t), "GCell"), u => GResult{st, t}, u => GResult{GState{g_put(g_heap(st), g_next(st), kt("GThunk", "", 0, 0, Con{t, Nil{}})), U32.add(g_next(st), 1)}, kt("GCell", "", g_next(st), 0, Nil{})})

@unsafe
def g_share_terms(
  +st: GState,
  +ts: List<&2, KTerm>,
  +done: List<&2, KTerm>,
) -> GTerms:
  match ts:
    case Nil{}:
      GTerms{st, List.reverse(&2, KTerm, done)}
    case Con{h, rest}:
      g_shared_term(rest, done, g_share(st, h))

@unsafe
def g_shared_term(rest, done, r):
  g_share_terms(g_state(r), rest, Con{g_term(r), done})

@unsafe
def g_share_head(
  +st: GState,
  +t: KTerm,
) -> GResult:
  kc(GResult, String.eq(tg(t), "All"), u => g_shared_domain(t, g_share(st, kid(t, 0))),
    u => kc(GResult, String.eq(tg(t), "Ctr") || String.eq(tg(t), "ADT") || String.eq(tg(t), "Mat") || String.eq(tg(t), "Eql") || String.eq(tg(t), "Min") || String.eq(tg(t), "Typ"), u => g_shared_head(t, g_share_terms(st, ks(t), Nil{})), u => GResult{st, t}))

@unsafe
def g_shared_head(t, r):
  GResult{g_states(r), k_with_children(t, g_terms(r))}

@unsafe
def g_cache(
  +st: GState,
  +id: U32,
  +t: KTerm,
) -> GState:
  GState{g_put(g_heap(st), id, kt("GValue", "", 0, 0, Con{t, Nil{}})), g_next(st)}

@unsafe
def g_wnf(
  +book: List<&2, KDef>,
  +st: GState,
  +t: KTerm,
) -> GResult:
  g_eval(book, st, t, Nil{}, 0, atom("Absent"), Nil{})

@unsafe
def g_eval(book, st, t, args, pending, fallback, stack):
  kc(GResult, String.eq(tg(t), "GCell"), u => g_cell(book, st, t, args, pending, fallback, stack, g_get(g_heap(st), ix(t))),
   u => kc(GResult, String.eq(tg(t), "App"), u => g_app(book, kid(t, 0), args, pending, fallback, stack, g_share(st, kid(t, 1))),
   u => kc(GResult, String.eq(tg(t), "Ann"), u => g_eval(book, st, kid(t, 0), args, pending, fallback, stack),
   u => kc(GResult, String.eq(tg(t), "Var") && U32.is_gt(terms_len(ks(t)), 0), u => g_eval(book, st, kid(t, 0), args, pending, fallback, stack),
   u => kc(GResult, String.eq(tg(t), "Let"), u => g_let(book, st, ks(t), Nil{}, args, pending, fallback, stack),
   u => kc(GResult, String.eq(tg(t), "Ref"), u => g_ref(book, st, t, args, stack, lookup(book, nm(t))),
   u => kc(GResult, String.eq(tg(t), "Min"), u => g_eval(book, st, kid(t, 0), Nil{}, 0, atom("Absent"), Con{GMinA{kid(t, 1), args}, stack}),
   u => kc(GResult, String.eq(tg(t), "Rwt"), u => g_eval(book, st, kid(t, 0), Nil{}, 0, atom("Absent"), Con{GRewrite{t, args, pending, fallback}, stack}),
   u => g_args(book, st, t, args, pending, fallback, stack)))))))))

@unsafe
def g_cell(book, st, t, args, pending, fallback, stack, cell):
  kc(GResult, String.eq(tg(cell), "GValue"), u => g_eval(book, st, kid(cell, 0), args, pending, fallback, stack), u => g_eval(book, st, kid(cell, 0), Nil{}, 0, atom("Absent"), Con{GFill{ix(t), args, pending, fallback}, stack}))

@unsafe
def g_app(book, fn, args, pending, fallback, stack, r):
  g_eval(book, g_state(r), fn, Con{g_term(r), args}, pending, fallback, stack)

@unsafe
def g_ref(book, st, t, args, stack, d):
  kc(GResult, String.eq(dk(d), "ADT"), u => g_return(book, st, norm_apply(kc(KTerm, U32.is_eq(da(d), 0), u => kt("ADT", nm(t), 0, 0, Nil{}), u => t), args), stack),
   u => kc(GResult, Bool.not(String.eq(tg(dv(d)), "Absent") || String.eq(tg(dv(d)), "Foreign")) && U32.is_le(da(d), terms_len(args)), u => g_eval(book, st, dv(d), args, da(d), norm_apply(t, args), stack), u => g_return(book, st, norm_apply(t, args), stack)))

@unsafe
def g_args(book, st, t, args, pending, fallback, stack):
  match args:
    case Nil{}:
      g_return(book, st, t, stack)
    case Con{x, rest}:
      kc(GResult, String.eq(tg(t), "Lam"), u => g_eval(book, st, subst(kid(t, 0), ix(t), x), rest, norm_dec(pending), fallback, stack),
       u => kc(GResult, String.eq(tg(t), "Mat"), u => g_eval(book, st, x, Nil{}, 0, atom("Absent"), Con{GMatch{t, x, rest, pending, fallback}, stack}),
       u => g_return(book, st, kc(KTerm, String.eq(tg(t), "Efq") && U32.is_gt(pending, 0), u => fallback, u => norm_apply(t, args)), stack)))

@unsafe
def g_return(book, st, t, stack):
  match stack:
    case Nil{}:
      GResult{st, t}
    case Con{frame, rest}:
      g_resume(book, st, t, frame, rest)

@unsafe
def g_resume(book, st, t, frame, stack):
  match frame:
    case GFill{id, args, pending, fallback}:
      g_filled(book, id, args, pending, fallback, stack, g_share_head(st, t))
    case GMatch{arm, raw, args, pending, fallback}:
      g_match(book, st, arm, arm, raw, t, args, pending, fallback, stack)
    case GMinA{other, args}:
      g_min_left(book, st, t, other, args, stack)
    case GMinB{other, args}:
      g_return(book, st, norm_apply(norm_min_right(other, t), args), stack)
    case GRewrite{original, args, pending, fallback}:
      kc(GResult, String.eq(tg(t), "Rfl"), u => g_eval(book, st, kid(original, 2), args, pending, fallback, stack), u => g_return(book, st, norm_apply(original, args), stack))

@unsafe
def g_filled(book, id, args, pending, fallback, stack, r):
  g_eval(book, g_cache(g_state(r), id, g_term(r)), g_term(r), args, pending, fallback, stack)

@unsafe
def g_min_left(book, st, a, b, args, stack):
  kc(GResult, String.eq(tg(a), "Qua") && U32.is_eq(qt(a), 2), u => g_eval(book, st, b, args, 0, atom("Absent"), stack),
   u => kc(GResult, String.eq(tg(a), "Qua") && U32.is_eq(qt(a), 0), u => g_return(book, st, norm_apply(a, args), stack), u => g_eval(book, st, b, Nil{}, 0, atom("Absent"), Con{GMinB{a, args}, stack})))

@unsafe
def g_match(book, st, arm, original, raw, x, args, pending, fallback, stack):
  kc(GResult, core_literal(x), u => g_match(book, st, arm, original, raw, core_literal_step(x), args, pending, fallback, stack), u =>
  kc(GResult, Bool.not(String.eq(tg(x), "Ctr")), u => g_return(book, st, norm_stuck(original, raw, args, pending, fallback), stack),
   u => kc(GResult, String.eq(tg(arm), "Ann"), u => g_match(book, st, kid(arm, 0), original, raw, x, args, pending, fallback, stack),
   u => kc(GResult, String.eq(tg(arm), "Mat"), u => kc(GResult, String.eq(nm(arm), nm(x)),
     u => g_eval(book, st, kid(arm, 0), norm_join(ks(x), args), kc(U32, U32.is_eq(pending, 0), u => 0, u => U32.add(norm_dec(pending), terms_len(ks(x)))), fallback, stack),
     u => g_match(book, st, kid(arm, 1), original, raw, x, args, pending, fallback, stack)),
   u => kc(GResult, String.eq(tg(arm), "Efq"), u => g_return(book, st, norm_stuck(original, raw, args, pending, fallback), stack), u => g_eval(book, st, arm, Con{x, args}, pending, fallback, stack))))))

@unsafe
def g_let(book, st, ts, bindings, args, pending, fallback, stack):
  match ts:
    case Nil{}:
      g_return(book, st, atom("Absent"), stack)
    case Con{h, rest}:
      kc(GResult, String.eq(tg(h), "Bind"), u => g_let_shared(book, h, rest, bindings, args, pending, fallback, stack, g_share(st, kid(h, 0))), u => g_eval(book, st, g_let_sub(h, bindings), args, pending, fallback, stack))

@unsafe
def g_let_shared(book, h, rest, bindings, args, pending, fallback, stack, r):
  g_let(book, g_state(r), rest, Con{kt("Bind", nm(h), ix(h), qt(h), Con{g_term(r), Nil{}}), bindings}, args, pending, fallback, stack)

@unsafe
def g_let_sub(t, bindings):
  match bindings:
    case Nil{}:
      t
    case Con{h, rest}:
      g_let_sub(subst(t, ix(h), kid(h, 0)), rest)

@unsafe
def graph_strong(book, t):
  g_start(book, t, norm_max(norm_book_bound(book), norm_max_term(t)))

@unsafe
def g_snf_go(
  +book: List<&2, KDef>,
  +st: GState,
  +t: KTerm,
  +stack: List<&2, KNormFrame>,
  +fresh: U32,
) -> KTerm:
  g_snf_head(book, stack, fresh, g_wnf(book, st, t))

@unsafe
def g_snf_head(book, stack, fresh, r):
  kc(KTerm, String.eq(tg(g_term(r)), "Lam") || String.eq(tg(g_term(r)), "All"), u => g_snf_open(book, g_state(r), norm_rebind(g_term(r), fresh), stack, U32.add(fresh, 1)), u => g_snf_open(book, g_state(r), g_term(r), stack, fresh))

@unsafe
def g_snf_open(book, st, t, stack, fresh):
  g_snf_children(book, st, t, Nil{}, ks(t), stack, fresh)

@unsafe
def g_snf_children(book, st, parent, done, todo, stack, fresh):
  match todo:
    case Nil{}:
      g_snf_return(book, st, k_snf_children(parent, List.reverse(&2, KTerm, done)), stack, fresh)
    case Con{h, rest}:
      g_snf_go(book, st, h, Con{KNormFrame{parent, done, rest}, stack}, fresh)

@unsafe
def g_snf_return(book, st, t, stack, fresh):
  match stack:
    case Nil{}:
      t
    case Con{KNormFrame{parent, done, todo}, rest}:
      g_snf_children(book, st, parent, Con{t, done}, todo, rest, fresh)


law g_start:
  for +book: List<&2, KDef>
  for +t: KTerm
  for +bound: U32
  KTerm

@unsafe
def g_start(book, t, bound):
  g_snf_go(book_cached(book, bound), GState{GEmpty{}, 1}, t, Nil{}, U32.add(bound, 1))

# A telescope domain is independent of its own binder; its deferred codomain
# stays outside the cell so opening that binder still substitutes the body.
@unsafe
def g_shared_domain(+t: KTerm, +r: GResult) -> GResult:
  match r:
    case GResult{state, term}:
      GResult{state, k_with_children(t, Con{term, Con{kid(t, 1), Nil{}}})}
