import Base

# Research slice: immutable syntax plus first-order environments and shared cells.
# There is no definition book: references are opaque. Match/rewrite/kind-meet
# semantics, subtyping and stack-safe quotation are intentionally outside scope.
# Inputs retain the production core's globally distinct binder-ID invariant.
# The syntactic support predicate does not establish that global invariant.
type SVBind is Data:
  SVBind{+binder: U32, +cell: U32}

type SVValue is Data:
  SVValue{+syntax: KTerm, +env: List<&2, SVBind>, +args: List<&2, U32>, +fields: List<&2, U32>}

type SVCell is Data:
  SVCell{+syntax: KTerm, +env: List<&2, SVBind>, +ready: Bool, +value: SVValue}

type SVHeap is Data:
  SVEmpty{}
  SVNode{+value: SVCell, +left: SVHeap, +right: SVHeap}

type SVState is Data:
  SVState{+heap: SVHeap, +next: U32, +fresh: U32, +steps: U32, +hits: U32}

type SVResult is Data:
  SVResult{+state: SVState, +value: SVValue}

type SVAllocated is Data:
  SVAllocated{+state: SVState, +cell: U32}

type SVFields is Data:
  SVFields{+state: SVState, +cells: List<&2, U32>}

type SVQuote is Data:
  SVQuote{+state: SVState, +term: KTerm}

type SVQuotes is Data:
  SVQuotes{+state: SVState, +terms: List<&2, KTerm>}

type SVCompared is Data:
  SVCompared{+state: SVState, +equal: Bool}

type SVObservation is Data:
  SVObservation{+term: KTerm, +steps: U32, +hits: U32, +cells: U32, +supported: Bool}

law sv_put:
  for +heap: SVHeap
  for +id: U32
  for +cell: SVCell
  SVHeap

law sv_eval:
  for +st: SVState
  for +t: KTerm
  for +env: List<&2, SVBind>
  SVResult

law sv_apply:
  for +st: SVState
  for +value: SVValue
  for +arg: U32
  SVResult

law sv_force:
  for +st: SVState
  for +id: U32
  SVResult

law sv_let:
  for +st: SVState
  for +items: List<&2, KTerm>
  for +outer: List<&2, SVBind>
  for +body: List<&2, SVBind>
  SVResult

law sv_quote:
  for +st: SVState
  for +value: SVValue
  SVQuote

law sv_quote_cells:
  for +st: SVState
  for +cells: List<&2, U32>
  SVQuotes

law sv_convert:
  for +st: SVState
  for +a: SVValue
  for +b: SVValue
  SVCompared

law sv_convert_cells:
  for +st: SVState
  for +as: List<&2, U32>
  for +bs: List<&2, U32>
  SVCompared

law sv_supported:
  for +t: KTerm
  Bool

@unsafe
def sv_empty_value() -> SVValue:
  SVValue{atom("Absent"), Nil{}, Nil{}, Nil{}}

@unsafe
def sv_empty_cell() -> SVCell:
  SVCell{atom("Absent"), Nil{}, False{}, sv_empty_value()}

@unsafe
def sv_get(+heap: SVHeap, +id: U32) -> SVCell:
  match heap:
    case SVEmpty{}:
      sv_empty_cell()
    case SVNode{value, left, right}:
      kc(SVCell, U32.is_eq(id, 0), u => value, u => kc(SVCell, U32.is_eq(U32.and(id, 1), 0), u => sv_get(left, U32.shr(id)), u => sv_get(right, U32.shr(id))))

@unsafe
def sv_put_node(+old: SVCell, +left: SVHeap, +right: SVHeap, +id: U32, +cell: SVCell) -> SVHeap:
  kc(SVHeap, U32.is_eq(id, 0), u => SVNode{cell, left, right}, u => kc(SVHeap, U32.is_eq(U32.and(id, 1), 0), u => SVNode{old, sv_put(left, U32.shr(id), cell), right}, u => SVNode{old, left, sv_put(right, U32.shr(id), cell)}))

@unsafe
def sv_put(heap, id, cell):
  match heap:
    case SVEmpty{}:
      sv_put_node(sv_empty_cell(), SVEmpty{}, SVEmpty{}, id, cell)
    case SVNode{old, left, right}:
      sv_put_node(old, left, right, id, cell)

@unsafe
def sv_lookup(+env: List<&2, SVBind>, +id: U32) -> U32:
  match env:
    case Nil{}:
      0
    case Con{SVBind{binder, cell}, rest}:
      kc(U32, U32.is_eq(binder, id), u => cell, u => sv_lookup(rest, id))

@unsafe
def sv_alloc(+st: SVState, +t: KTerm, +env: List<&2, SVBind>) -> SVAllocated:
  match st:
    case SVState{heap, next, fresh, steps, hits}:
      SVAllocated{SVState{sv_put(heap, next, SVCell{t, env, False{}, sv_empty_value()}), U32.add(next, 1), fresh, steps, hits}, next}

@unsafe
def sv_neutral(+st: SVState, +name: String) -> SVAllocated:
  match st:
    case SVState{heap, next, fresh, steps, hits}:
      SVAllocated{SVState{sv_put(heap, next, SVCell{var(name, fresh), Nil{}, True{}, SVValue{var(name, fresh), Nil{}, Nil{}, Nil{}}}), U32.add(next, 1), U32.add(fresh, 1), steps, hits}, next}

@unsafe
def sv_fresh_id(+st: SVState) -> U32:
  match st:
    case SVState{heap, next, fresh, steps, hits}:
      fresh

@unsafe
def sv_tick(+st: SVState) -> SVState:
  match st:
    case SVState{heap, next, fresh, steps, hits}:
      SVState{heap, next, fresh, U32.add(steps, 1), hits}

@unsafe
def sv_cached(+st: SVState, +id: U32, +value: SVValue) -> SVState:
  match st:
    case SVState{heap, next, fresh, steps, hits}:
      SVState{sv_put(heap, id, SVCell{atom("Absent"), Nil{}, True{}, value}), next, fresh, steps, hits}

@unsafe
def sv_forced(+id: U32, +r: SVResult) -> SVResult:
  match r:
    case SVResult{st, value}:
      SVResult{sv_cached(st, id, value), value}

@unsafe
def sv_force_cell(+st: SVState, +id: U32, +cell: SVCell) -> SVResult:
  match st cell:
    case SVState{heap, next, fresh, steps, hits} SVCell{syntax, env, ready, value}:
      kc(SVResult, ready, u => SVResult{SVState{heap, next, fresh, steps, U32.add(hits, 1)}, value}, u => sv_forced(id, sv_eval(st, syntax, env)))

@unsafe
def sv_force(st, id):
  match st:
    case SVState{heap, next, fresh, steps, hits}:
      sv_force_cell(st, id, sv_get(heap, id))

law sv_fields:
  for +st: SVState
  for +terms: List<&2, KTerm>
  for +env: List<&2, SVBind>
  for +done: List<&2, U32>
  SVFields

@unsafe
def sv_fields_added(+rest: List<&2, KTerm>, +env: List<&2, SVBind>, +done: List<&2, U32>, +r: SVAllocated) -> SVFields:
  match r:
    case SVAllocated{st, cell}:
      sv_fields(st, rest, env, Con{cell, done})

@unsafe
def sv_fields(st, terms, env, done):
  match terms:
    case Nil{}:
      SVFields{st, List.reverse(&2, U32, done)}
    case Con{t, rest}:
      sv_fields_added(rest, env, done, sv_alloc(st, t, env))

@unsafe
def sv_head_fields(+t: KTerm, +env: List<&2, SVBind>, +r: SVFields) -> SVResult:
  match r:
    case SVFields{st, fields}:
      SVResult{st, SVValue{t, env, Nil{}, fields}}

@unsafe
def sv_head(+st: SVState, +t: KTerm, +env: List<&2, SVBind>) -> SVResult:
  kc(SVResult, String.eq(tg(t), "Lam") || String.eq(tg(t), "All"), u => SVResult{st, SVValue{t, env, Nil{}, Nil{}}}, u => sv_head_fields(t, env, sv_fields(st, ks(t), env, Nil{})))

@unsafe
def sv_apply(st, value, arg):
  match value:
    case SVValue{t, env, args, fields}:
      kc(SVResult, String.eq(tg(t), "Lam"), u => sv_eval(st, kid(t, 0), Con{SVBind{ix(t), arg}, env}), u => SVResult{st, SVValue{t, env, Con{arg, args}, fields}})

@unsafe
def sv_app_value(+cell: U32, +r: SVResult) -> SVResult:
  match r:
    case SVResult{st, value}:
      sv_apply(st, value, cell)

@unsafe
def sv_app_allocated(+fn: KTerm, +env: List<&2, SVBind>, +r: SVAllocated) -> SVResult:
  match r:
    case SVAllocated{st, cell}:
      sv_app_value(cell, sv_eval(st, fn, env))

@unsafe
def sv_variable(+st: SVState, +t: KTerm, +env: List<&2, SVBind>, +cell: U32) -> SVResult:
  kc(SVResult, U32.is_gt(terms_len(ks(t)), 0), u => sv_eval(st, kid(t, 0), env), u => kc(SVResult, U32.is_eq(cell, 0), u => SVResult{st, SVValue{t, Nil{}, Nil{}, Nil{}}}, u => sv_force(st, cell)))

@unsafe
def sv_let_added(+items: List<&2, KTerm>, +outer: List<&2, SVBind>, +body: List<&2, SVBind>, +binder: U32, +r: SVAllocated) -> SVResult:
  match r:
    case SVAllocated{st, cell}:
      sv_let(st, items, outer, Con{SVBind{binder, cell}, body})

@unsafe
def sv_let_tail(+st: SVState, +t: KTerm, +tail: List<&2, KTerm>, +outer: List<&2, SVBind>, +body: List<&2, SVBind>) -> SVResult:
  match tail:
    case Nil{}:
      sv_eval(st, t, body)
    case Con{head, rest}:
      sv_let_added(tail, outer, body, ix(t), sv_alloc(st, kid(t, 0), outer))

@unsafe
def sv_let(st, items, outer, body):
  match items:
    case Nil{}:
      SVResult{st, sv_empty_value()}
    case Con{t, tail}:
      sv_let_tail(st, t, tail, outer, body)

@unsafe
def sv_eval_node(+st: SVState, +t: KTerm, +env: List<&2, SVBind>) -> SVResult:
  kc(SVResult, String.eq(tg(t), "App"), u => sv_app_allocated(kid(t, 0), env, sv_alloc(st, kid(t, 1), env)),
    u => kc(SVResult, String.eq(tg(t), "Var"), u => sv_variable(st, t, env, sv_lookup(env, ix(t))),
    u => kc(SVResult, String.eq(tg(t), "Ann"), u => sv_eval(st, kid(t, 0), env),
    u => kc(SVResult, String.eq(tg(t), "Let"), u => sv_let(st, ks(t), env, env),
    u => sv_head(st, t, env)))))

@unsafe
def sv_eval(st, t, env):
  sv_eval_node(sv_tick(st), t, env)

@unsafe
def sv_quote_result(+r: SVResult) -> SVQuote:
  match r:
    case SVResult{st, value}:
      sv_quote(st, value)

@unsafe
def sv_quote_cons(+head: KTerm, +r: SVQuotes) -> SVQuotes:
  match r:
    case SVQuotes{st, terms}:
      SVQuotes{st, Con{head, terms}}

@unsafe
def sv_quote_cell_done(+rest: List<&2, U32>, +r: SVQuote) -> SVQuotes:
  match r:
    case SVQuote{st, term}:
      sv_quote_cons(term, sv_quote_cells(st, rest))

@unsafe
def sv_quote_cells(st, cells):
  match cells:
    case Nil{}:
      SVQuotes{st, Nil{}}
    case Con{cell, rest}:
      sv_quote_cell_done(rest, sv_quote_result(sv_force(st, cell)))

@unsafe
def sv_reapply(+head: KTerm, +args: List<&2, KTerm>) -> KTerm:
  match args:
    case Nil{}:
      head
    case Con{arg, rest}:
      sv_reapply(app(head, arg), rest)

@unsafe
def sv_quote_spine_done(+head: KTerm, +r: SVQuotes) -> SVQuote:
  match r:
    case SVQuotes{st, args}:
      SVQuote{st, sv_reapply(head, args)}

@unsafe
def sv_quote_with_spine(+args: List<&2, U32>, +r: SVQuote) -> SVQuote:
  match r:
    case SVQuote{st, term}:
      sv_quote_spine_done(term, sv_quote_cells(st, List.reverse(&2, U32, args)))

@unsafe
def sv_quote_fields_done(+t: KTerm, +args: List<&2, U32>, +r: SVQuotes) -> SVQuote:
  match r:
    case SVQuotes{st, fields}:
      sv_quote_spine_done(KTerm{tg(t), nm(t), ix(t), qt(t), fields, rm(t)}, sv_quote_cells(st, List.reverse(&2, U32, args)))

@unsafe
def sv_quote_lam_done(+t: KTerm, +id: U32, +r: SVQuote) -> SVQuote:
  match r:
    case SVQuote{st, body}:
      SVQuote{st, kt("Lam", nm(t), id, qt(t), [body])}

@unsafe
def sv_quote_lam_open(+t: KTerm, +env: List<&2, SVBind>, +id: U32, +r: SVAllocated) -> SVQuote:
  match r:
    case SVAllocated{st, cell}:
      sv_quote_lam_done(t, id, sv_quote_result(sv_eval(st, kid(t, 0), Con{SVBind{ix(t), cell}, env})))

@unsafe
def sv_quote_all_done(+t: KTerm, +id: U32, +domain: KTerm, +r: SVQuote) -> SVQuote:
  match r:
    case SVQuote{st, body}:
      SVQuote{st, all(qt(t), nm(t), id, domain, body)}

@unsafe
def sv_quote_all_open(+t: KTerm, +env: List<&2, SVBind>, +id: U32, +domain: KTerm, +r: SVAllocated) -> SVQuote:
  match r:
    case SVAllocated{st, cell}:
      sv_quote_all_done(t, id, domain, sv_quote_result(sv_eval(st, kid(t, 1), Con{SVBind{ix(t), cell}, env})))

@unsafe
def sv_quote_all_domain(+t: KTerm, +env: List<&2, SVBind>, +r: SVQuote) -> SVQuote:
  match r:
    case SVQuote{st, domain}:
      sv_quote_all_open(t, env, sv_fresh_id(st), domain, sv_neutral(st, nm(t)))

@unsafe
def sv_quote(st, value):
  match value:
    case SVValue{t, env, args, fields}:
      kc(SVQuote, String.eq(tg(t), "Lam"), u => sv_quote_lam_open(t, env, sv_fresh_id(st), sv_neutral(st, nm(t))),
        u => kc(SVQuote, String.eq(tg(t), "All"), u => sv_quote_with_spine(args, sv_quote_all_domain(t, env, sv_quote_result(sv_eval(st, kid(t, 0), env)))),
        u => sv_quote_fields_done(t, args, sv_quote_cells(st, fields))))

@unsafe
def sv_convert_second(+a: SVValue, +r: SVResult) -> SVCompared:
  match r:
    case SVResult{st, b}:
      sv_convert(st, a, b)

@unsafe
def sv_convert_eval_second(+b: KTerm, +env: List<&2, SVBind>, +r: SVResult) -> SVCompared:
  match r:
    case SVResult{st, a}:
      sv_convert_second(a, sv_eval(st, b, env))

@unsafe
def sv_convert_force_second(+b: U32, +r: SVResult) -> SVCompared:
  match r:
    case SVResult{st, a}:
      sv_convert_second(a, sv_force(st, b))

@unsafe
def sv_convert_cells_done(+as: List<&2, U32>, +bs: List<&2, U32>, +r: SVCompared) -> SVCompared:
  match r:
    case SVCompared{st, equal}:
      kc(SVCompared, equal, u => sv_convert_cells(st, as, bs), u => r)

@unsafe
def sv_env_exact(+a: List<&2, SVBind>, +b: List<&2, SVBind>) -> Bool:
  match a b:
    case Nil{} Nil{}:
      True{}
    case Con{SVBind{ai, ac}, ar} Con{SVBind{bi, bc}, br}:
      U32.is_eq(ai, bi) && U32.is_eq(ac, bc) && sv_env_exact(ar, br)
    case other_a other_b:
      False{}

@unsafe
def sv_suspensions_exact(+a: SVCell, +b: SVCell) -> Bool:
  match a b:
    case SVCell{at, ae, ar, av} SVCell{bt, be, br, bv}:
      Bool.not(ar || br) && sv_env_exact(ae, be) && norm_exact(at, bt)

@unsafe
def sv_cells_exact(+st: SVState, +a: U32, +b: U32) -> Bool:
  match st:
    case SVState{heap, next, fresh, steps, hits}:
      kc(Bool, U32.is_eq(a, b), u => True{}, u => sv_suspensions_exact(sv_get(heap, a), sv_get(heap, b)))

@unsafe
def sv_convert_cells(st, as, bs):
  match as bs:
    case Nil{} Nil{}:
      SVCompared{st, True{}}
    case Con{a, ar} Con{b, br}:
      kc(SVCompared, sv_cells_exact(st, a, b), u => sv_convert_cells(st, ar, br), u => sv_convert_cells_done(ar, br, sv_convert_force_second(b, sv_force(st, a))))
    case other_a other_b:
      SVCompared{st, False{}}

@unsafe
def sv_convert_eta_second(+b: SVValue, +cell: U32, +r: SVResult) -> SVCompared:
  match r:
    case SVResult{st, a}:
      sv_convert_second(a, sv_apply(st, b, cell))

@unsafe
def sv_convert_eta(+a: SVValue, +b: SVValue, +r: SVAllocated) -> SVCompared:
  match r:
    case SVAllocated{st, cell}:
      sv_convert_eta_second(b, cell, sv_apply(st, a, cell))

@unsafe
def sv_convert_all_open(+a: KTerm, +ae: List<&2, SVBind>, +b: KTerm, +be: List<&2, SVBind>, +r: SVAllocated) -> SVCompared:
  match r:
    case SVAllocated{st, cell}:
      sv_convert_eval_second(kid(b, 1), Con{SVBind{ix(b), cell}, be}, sv_eval(st, kid(a, 1), Con{SVBind{ix(a), cell}, ae}))

@unsafe
def sv_convert_all_domain(+a: KTerm, +ae: List<&2, SVBind>, +b: KTerm, +be: List<&2, SVBind>, +r: SVCompared) -> SVCompared:
  match r:
    case SVCompared{st, equal}:
      kc(SVCompared, equal, u => sv_convert_all_open(a, ae, b, be, sv_neutral(st, "_")), u => r)

@unsafe
def sv_same_head(+a: KTerm, +b: KTerm) -> Bool:
  String.eq(tg(a), tg(b)) && kc(Bool, String.eq(tg(a), "Var"), u => U32.is_eq(ix(a), ix(b)),
    u => kc(Bool, String.eq(tg(a), "Ref") || String.eq(tg(a), "Ctr") || String.eq(tg(a), "ADT"), u => String.eq(nm(a), nm(b)),
    u => kc(Bool, String.eq(tg(a), "Qua"), u => U32.is_eq(qt(a), qt(b)), u => True{})))

@unsafe
def sv_same_length(+a: List<&2, U32>, +b: List<&2, U32>) -> Bool:
  match a b:
    case Nil{} Nil{}:
      True{}
    case Con{ah, ar} Con{bh, br}:
      sv_same_length(ar, br)
    case other_a other_b:
      False{}

@unsafe
def sv_convert_nodes(+st: SVState, +a: KTerm, +ae: List<&2, SVBind>, +aa: List<&2, U32>, +af: List<&2, U32>, +b: KTerm, +be: List<&2, SVBind>, +ba: List<&2, U32>, +bf: List<&2, U32>) -> SVCompared:
  kc(SVCompared, sv_same_length(aa, ba) && sv_same_length(af, bf), u => kc(SVCompared, String.eq(tg(a), "All") && String.eq(tg(b), "All"),
    u => kc(SVCompared, U32.is_eq(qt(a), qt(b)), u => sv_convert_cells_done(List.reverse(&2, U32, aa), List.reverse(&2, U32, ba), sv_convert_all_domain(a, ae, b, be, sv_convert_eval_second(kid(b, 0), be, sv_eval(st, kid(a, 0), ae)))), u => SVCompared{st, False{}}),
    u => kc(SVCompared, sv_same_head(a, b), u => sv_convert_cells_done(List.reverse(&2, U32, aa), List.reverse(&2, U32, ba), sv_convert_cells(st, af, bf)), u => SVCompared{st, False{}})), u => SVCompared{st, False{}})

@unsafe
def sv_convert(st, a, b):
  match a b:
    case SVValue{at, ae, aa, af} SVValue{bt, be, ba, bf}:
      kc(SVCompared, String.eq(tg(at), "Lam") || String.eq(tg(bt), "Lam"), u => sv_convert_eta(a, b, sv_neutral(st, "_")), u => sv_convert_nodes(st, at, ae, aa, af, bt, be, ba, bf))

@unsafe
def sv_supported_terms(+terms: List<&2, KTerm>) -> Bool:
  match terms:
    case Nil{}:
      True{}
    case Con{t, rest}:
      sv_supported(t) && sv_supported_terms(rest)

law sv_supported_let:
  for +items: List<&2, KTerm>
  Bool

@unsafe
def sv_supported_let_tail(+t: KTerm, +tail: List<&2, KTerm>) -> Bool:
  match tail:
    case Nil{}:
      sv_supported(t)
    case Con{head, rest}:
      String.eq(tg(t), "Bind") && U32.is_lt(ix(t), 2147483648) && U32.is_le(qt(t), 2) && List.is_empty(&2, String, rm(t)) && U32.is_eq(terms_len(ks(t)), 1) && sv_supported(kid(t, 0)) && sv_supported_let(tail)

@unsafe
def sv_supported_let(items):
  match items:
    case Nil{}:
      False{}
    case Con{t, tail}:
      sv_supported_let_tail(t, tail)

@unsafe
def sv_supported_tag(+t: KTerm) -> Bool:
  kc(Bool, String.eq(tg(t), "Let"), u => sv_supported_let(ks(t)),
    u => kc(Bool, String.eq(tg(t), "Lam"), u => U32.is_eq(terms_len(ks(t)), 1) && sv_supported_terms(ks(t)),
    u => kc(Bool, String.eq(tg(t), "All") || String.eq(tg(t), "App") || String.eq(tg(t), "Ann"), u => U32.is_eq(terms_len(ks(t)), 2) && sv_supported_terms(ks(t)),
    u => kc(Bool, String.eq(tg(t), "Var"), u => U32.is_le(terms_len(ks(t)), 1) && sv_supported_terms(ks(t)),
    u => kc(Bool, String.eq(tg(t), "Ref") || String.eq(tg(t), "Qnt") || String.eq(tg(t), "Qua") || String.eq(tg(t), "Rfl"), u => U32.is_eq(terms_len(ks(t)), 0),
    u => kc(Bool, String.eq(tg(t), "Typ"), u => U32.is_eq(terms_len(ks(t)), 1) && sv_supported_terms(ks(t)),
    u => kc(Bool, String.eq(tg(t), "Eql"), u => U32.is_eq(terms_len(ks(t)), 3) && sv_supported_terms(ks(t)),
    u => (String.eq(tg(t), "Ctr") || String.eq(tg(t), "ADT")) && sv_supported_terms(ks(t)))))))))

@unsafe
def sv_supported(t):
  match t:
    case KTerm{tag, name, id, quant, kids, removed}:
      U32.is_lt(id, 2147483648) && U32.is_le(quant, 2) && kc(Bool, List.is_empty(&2, String, removed), u => sv_supported_tag(t), u => False{})

@unsafe
def sv_initial(+fresh: U32) -> SVState:
  SVState{SVEmpty{}, 1, fresh, 0, 0}

@unsafe
def sv_observation(+supported: Bool, +r: SVQuote) -> SVObservation:
  match r:
    case SVQuote{SVState{heap, next, fresh, steps, hits}, term}:
      SVObservation{term, steps, hits, U32.sub(next, 1), supported}

@unsafe
def sv_observe(+t: KTerm) -> SVObservation:
  kc(SVObservation, sv_supported(t), u => sv_observation(True{}, sv_quote_result(sv_eval(sv_initial(U32.add(norm_max_term(t), 1)), t, Nil{}))), u => SVObservation{kt("Error", "unsupported semantic-value slice", 0, 0, Nil{}), 0, 0, 0, False{}})

@unsafe
def sv_head_observation(+r: SVResult) -> SVObservation:
  match r:
    case SVResult{SVState{heap, next, fresh, steps, hits}, SVValue{t, env, args, fields}}:
      SVObservation{t, steps, hits, U32.sub(next, 1), True{}}

@unsafe
def sv_observe_head(+t: KTerm) -> SVObservation:
  kc(SVObservation, sv_supported(t), u => sv_head_observation(sv_eval(sv_initial(U32.add(norm_max_term(t), 1)), t, Nil{})), u => SVObservation{kt("Error", "unsupported semantic-value slice", 0, 0, Nil{}), 0, 0, 0, False{}})

@unsafe
def sv_equal_result(+r: SVCompared) -> Bool:
  match r:
    case SVCompared{st, equal}:
      equal

@unsafe
def sv_equal(+a: KTerm, +b: KTerm) -> Bool:
  kc(Bool, sv_supported(a) && sv_supported(b), u => kc(Bool, norm_exact(a, b), u => True{}, u => sv_equal_result(sv_convert_eval_second(b, Nil{}, sv_eval(sv_initial(U32.add(norm_max(norm_max_term(a), norm_max_term(b)), 1)), a, Nil{})))), u => False{})
