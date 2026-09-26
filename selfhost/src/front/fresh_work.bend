# Explicit continuations keep alpha-renaming independent of host stack depth.
# Allocation order and lexical scope match the original recursive traversal.
type FFFrame is Data:
  FFAllA{+term: KTerm, +env: List<&2,KTerm>, +id: U32}
  FFAllB{+term: KTerm, +id: U32, +typ: KTerm}
  FFLambda{+term: KTerm, +id: U32}
  FFKids{+term: KTerm, +env: List<&2,KTerm>, +pending: List<&2,KTerm>, +built: List<&2,KTerm>}
  FFLetValue{+env: List<&2,KTerm>, +bodyenv: List<&2,KTerm>, +id: U32, +binding: KTerm, +pending: List<&2,KTerm>, +built: List<&2,KTerm>}
  FFLetBody{+built: List<&2,KTerm>}

law ffw_walk:
  for +term: KTerm
  for +env: List<&2,KTerm>
  for +next: U32
  for +stack: List<&2,FFFrame>
  FFresh
law ffw_done:
  for +term: KTerm
  for +next: U32
  for +stack: List<&2,FFFrame>
  FFresh
law ffw_frame:
  for +frame: FFFrame
  for +value: KTerm
  for +next: U32
  for +stack: List<&2,FFFrame>
  FFresh
law ffw_kids:
  for +term: KTerm
  for +env: List<&2,KTerm>
  for +pending: List<&2,KTerm>
  for +built: List<&2,KTerm>
  for +next: U32
  for +stack: List<&2,FFFrame>
  FFresh
law ffw_let:
  for +env: List<&2,KTerm>
  for +bodyenv: List<&2,KTerm>
  for +items: List<&2,KTerm>
  for +built: List<&2,KTerm>
  for +next: U32
  for +stack: List<&2,FFFrame>
  FFresh
law ffw_let_tail:
  for +env: List<&2,KTerm>
  for +bodyenv: List<&2,KTerm>
  for +term: KTerm
  for +tail: List<&2,KTerm>
  for +built: List<&2,KTerm>
  for +next: U32
  for +stack: List<&2,FFFrame>
  FFresh

@unsafe
def f_fresh_stack(
  +term: KTerm,
  +env: List<&2,KTerm>,
  +next: U32,
) -> FFresh:
  ffw_walk(term, env, next, Nil{})
@unsafe
def ffw_walk(term, env, next, stack):
  f_choose(FFresh, String.eq(tg(term), "Var"), u => ffw_done(f_rename_var(term, env), next, stack),
    u => f_choose(FFresh, String.eq(tg(term), "All"), u => ffw_walk(kid(term, 0), env, U32.add(next, 1), Con{FFAllA{term, env, next}, stack}),
    u => f_choose(FFresh, String.eq(tg(term), "Lam"), u => ffw_walk(kid(term, 0), Con{kt("Map", "", ix(term), 0, [var(nm(term), next)]), env}, U32.add(next, 1), Con{FFLambda{term, next}, stack}),
    u => f_choose(FFresh, String.eq(tg(term), "Let"), u => ffw_let(env, env, ks(term), Nil{}, next, stack),
    u => ffw_kids(term, env, ks(term), Nil{}, next, stack)))))
@unsafe
def ffw_done(term, next, stack):
  match stack:
    case Nil{}:
      FFresh{term, next}
    case Con{frame, rest}:
      ffw_frame(frame, term, next, rest)
@unsafe
def ffw_frame(frame, value, next, stack):
  match frame:
    case FFAllA{+term, +env, +id}:
      ffw_walk(kid(term, 1), Con{kt("Map", "", ix(term), 0, [var(nm(term), id)]), env}, next, Con{FFAllB{term, id, value}, stack})
    case FFAllB{+term, id, typ}:
      ffw_done(kt("All", nm(term), id, qt(term), [typ, value]), next, stack)
    case FFLambda{+term, id}:
      ffw_done(kt("Lam", nm(term), id, qt(term), [value]), next, stack)
    case FFKids{term, env, pending, built}:
      ffw_kids(term, env, pending, Con{value, built}, next, stack)
    case FFLetValue{env, bodyenv, +id, +binding, pending, built}:
      ffw_let(env, Con{kt("Map", "", ix(binding), 0, [var(nm(binding), id)]), bodyenv}, pending, Con{kt("Bind", nm(binding), id, qt(binding), [value]), built}, next, stack)
    case FFLetBody{built}:
      ffw_done(kt("Let", "", 0, 1, ffw_reverse_onto(built, [value])), next, stack)
@unsafe
def ffw_kids(term, env, pending, built, next, stack):
  match pending:
    case Nil{}:
      ffw_done(KTerm{tg(term), nm(term), ix(term), qt(term), List.reverse(&2,KTerm,built), rm(term)}, next, stack)
    case Con{head, rest}:
      ffw_walk(head, env, next, Con{FFKids{term, env, rest, built}, stack})
@unsafe
def ffw_let(env, bodyenv, items, built, next, stack):
  match items:
    case Nil{}:
      ffw_done(kt("Error", "empty core let", 0, 0, Nil{}), next, stack)
    case Con{term, tail}:
      ffw_let_tail(env, bodyenv, term, tail, built, next, stack)
@unsafe
def ffw_let_tail(env, bodyenv, term, tail, built, next, stack):
  match tail:
    case Nil{}:
      ffw_walk(term, bodyenv, next, Con{FFLetBody{built}, stack})
    case Con{head, rest}:
      ffw_walk(kid(term, 0), env, U32.add(next, 1), Con{FFLetValue{env, bodyenv, next, term, tail, built}, stack})

law ffw_reverse_onto:
  for +items: List<&2,KTerm>
  for +onto: List<&2,KTerm>
  List<&2,KTerm>

@unsafe
def ffw_reverse_onto(items, onto):
  match items:
    case Nil{}:
      onto
    case Con{head, tail}:
      ffw_reverse_onto(tail, Con{head, onto})

# Definition lists require the same explicit continuation discipline: computing
# the freshened tail before constructing its enclosing list consumes host stack
# even when each individual term is shallow. Constructor-definition lists share
# this worklist, so both declaration breadth and nested list depth are bounded
# by heap storage rather than JavaScript's call stack.
type FFDefFrame is Data:
  FFDefFrame{+definition: KDef, +pending: List<&2,KDef>, +built: List<&2,KDef>, +typ: KTerm, +value: KTerm}

law ffd_walk:
  for +book: List<&2,KDef>
  for +next: U32
  for +built: List<&2,KDef>
  for +stack: List<&2,FFDefFrame>
  FFreshDefs
law ffd_type:
  for +definition: KDef
  for +pending: List<&2,KDef>
  for +built: List<&2,KDef>
  for +stack: List<&2,FFDefFrame>
  for +result: FFresh
  FFreshDefs
law ffd_value:
  for +definition: KDef
  for +pending: List<&2,KDef>
  for +built: List<&2,KDef>
  for +stack: List<&2,FFDefFrame>
  for +typ: KTerm
  for +result: FFresh
  FFreshDefs
law ffd_done:
  for +book: List<&2,KDef>
  for +next: U32
  for +stack: List<&2,FFDefFrame>
  FFreshDefs
law ffd_frame:
  for +frame: FFDefFrame
  for +ctors: List<&2,KDef>
  for +next: U32
  for +stack: List<&2,FFDefFrame>
  FFreshDefs

@unsafe
def f_fresh_book_stack(
  +book: List<&2,KDef>,
  +next: U32,
) -> FFreshDefs:
  ffd_walk(book, next, Nil{}, Nil{})
@unsafe
def ffd_walk(book, next, built, stack):
  match book:
    case Nil{}:
      ffd_done(List.reverse(&2,KDef,built), next, stack)
    case Con{+definition, pending}:
      ffd_type(definition, pending, built, stack, f_fresh_term(dt(definition), Nil{}, next))
@unsafe
def ffd_type(definition, pending, built, stack, result):
  match result:
    case FFresh{typ, next}:
      ffd_value(definition, pending, built, stack, typ, f_fresh_term(dv(definition), Nil{}, next))
@unsafe
def ffd_value(definition, pending, built, stack, typ, result):
  match result:
    case FFresh{value, next}:
      ffd_walk(dc(definition), next, Nil{}, Con{FFDefFrame{definition, pending, built, typ, value}, stack})
@unsafe
def ffd_done(book, next, stack):
  match stack:
    case Nil{}:
      FFreshDefs{book, next}
    case Con{frame, rest}:
      ffd_frame(frame, book, next, rest)
@unsafe
def ffd_frame(frame, ctors, next, stack):
  match frame:
    case FFDefFrame{+definition, pending, built, typ, value}:
      ffd_walk(pending, next, Con{KDef{dn(definition), dk(definition), da(definition), dx(definition), typ, value, ctors, db(definition), du(definition)}, built}, stack)
