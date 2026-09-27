# Research only: one scope plan and worklist for freshening and template shifts.
# Mode 0 freshens lexically; mode 1 shifts every binder/reference identifier.
# The public baseline operations are retained as independent comparison controls.
type A3Frame is Data:
  A3Frame{+root: KTerm, +outer: List<&2,KTerm>, +inner: List<&2,KTerm>, +shape: U32, +pending: List<&2,KTerm>, +built: List<&2,KTerm>, +field: KTerm}

law a3_walk:
  for +mode: U32
  for +offset: U32
  for +term: KTerm
  for +env: List<&2,KTerm>
  for +next: U32
  for +stack: List<&2,A3Frame>
  FFresh
law a3_done:
  for +mode: U32
  for +offset: U32
  for +term: KTerm
  for +next: U32
  for +stack: List<&2,A3Frame>
  FFresh
law a3_resume:
  for +mode: U32
  for +offset: U32
  for +term: KTerm
  for +next: U32
  for +frame: A3Frame
  for +stack: List<&2,A3Frame>
  FFresh
law a3_kids:
  for +mode: U32
  for +offset: U32
  for +root: KTerm
  for +outer: List<&2,KTerm>
  for +inner: List<&2,KTerm>
  for +shape: U32
  for +pending: List<&2,KTerm>
  for +built: List<&2,KTerm>
  for +next: U32
  for +stack: List<&2,A3Frame>
  FFresh
law a3_child:
  for +mode: U32
  for +offset: U32
  for +root: KTerm
  for +outer: List<&2,KTerm>
  for +inner: List<&2,KTerm>
  for +shape: U32
  for +head: KTerm
  for +rest: List<&2,KTerm>
  for +built: List<&2,KTerm>
  for +next: U32
  for +stack: List<&2,A3Frame>
  FFresh

# Scope shape: ordinary children, all scoped, only final child scoped, or
# parallel bindings with outer RHS scope and extended final-body scope.
@unsafe
def a3_shape(
  +term: KTerm,
) -> U32:
  kc(U32, String.eq(tg(term), "Lam"), u => 1,
    u => kc(U32, String.eq(tg(term), "All"), u => 2,
      u => kc(U32, String.eq(tg(term), "Let"), u => 3, u => 0)))

@unsafe
def a3_bound(
  +env: List<&2,KTerm>,
  +old: U32,
  +name: String,
  +fresh: U32,
) -> List<&2,KTerm>:
  Con{kt("Map", "", old, 0, [var(name, fresh)]), env}

@unsafe
def a3_shift_head(
  +term: KTerm,
  +offset: U32,
) -> KTerm:
  KTerm{tg(term), nm(term), kc(U32, String.eq(tg(term), "Var") || String.eq(tg(term), "All") || String.eq(tg(term), "Lam") || String.eq(tg(term), "Bind") || String.eq(tg(term), "Sub"), u => U32.add(ix(term), offset), u => ix(term)), qt(term), Nil{}, rm(term)}

@unsafe
def a3_empty(
  +terms: List<&2,KTerm>,
) -> Bool:
  match terms:
    case Nil{}: True{}
    case Con{head, tail}: False{}

@unsafe
def a3_enter(
  +term: KTerm,
  +env: List<&2,KTerm>,
  +next: U32,
  +shape: U32,
  +stack: List<&2,A3Frame>,
) -> FFresh:
  kc(FFresh, U32.is_eq(shape, 1) || U32.is_eq(shape, 2),
    u => a3_kids(0, 0, kt(tg(term), nm(term), next, qt(term), Nil{}), env, a3_bound(env, ix(term), nm(term), next), shape, kc(List<&2,KTerm>, U32.is_eq(shape, 1), u => [kid(term, 0)], u => [kid(term, 0), kid(term, 1)]), Nil{}, U32.add(next, 1), stack),
    u => kc(FFresh, U32.is_eq(shape, 3),
      u => kc(FFresh, a3_empty(ks(term)), u => a3_done(0, 0, kt("Error", "empty core let", 0, 0, Nil{}), next, stack), u => a3_kids(0, 0, kt("Let", "", 0, 1, Nil{}), env, env, shape, ks(term), Nil{}, next, stack)),
      u => a3_kids(0, 0, term, env, env, shape, ks(term), Nil{}, next, stack)))

@unsafe
def a3_walk(mode, offset, term, env, next, stack):
  kc(FFresh, U32.is_eq(mode, 1),
    u => a3_kids(mode, offset, a3_shift_head(term, offset), env, env, 0, ks(term), Nil{}, next, stack),
    u => kc(FFresh, String.eq(tg(term), "Var"), u => a3_done(mode, offset, f_rename_var(term, env), next, stack), u => a3_enter(term, env, next, a3_shape(term), stack)))

@unsafe
def a3_kids(mode, offset, root, outer, inner, shape, pending, built, next, stack):
  match pending:
    case Nil{}:
      a3_done(mode, offset, KTerm{tg(root), nm(root), ix(root), qt(root), List.reverse(&2,KTerm,built), rm(root)}, next, stack)
    case Con{head, rest}:
      a3_child(mode, offset, root, outer, inner, shape, head, rest, built, next, stack)

@unsafe
def a3_body_scope(
  +shape: U32,
  +rest: List<&2,KTerm>,
) -> Bool:
  U32.is_eq(shape, 1) || ((U32.is_eq(shape, 2) || U32.is_eq(shape, 3)) && a3_empty(rest))

@unsafe
def a3_child(mode, offset, root, outer, inner, shape, head, rest, built, next, stack):
  kc(FFresh, U32.is_eq(shape, 3) && Bool.not(a3_empty(rest)),
    u => a3_walk(mode, offset, kid(head, 0), outer, U32.add(next, 1), Con{A3Frame{root, outer, a3_bound(inner, ix(head), nm(head), next), shape, rest, built, kt("Bind", nm(head), next, qt(head), Nil{})}, stack}),
    u => a3_walk(mode, offset, head, kc(List<&2,KTerm>, a3_body_scope(shape, rest), u => inner, u => outer), next, Con{A3Frame{root, outer, inner, shape, rest, built, atom("Absent")}, stack}))

@unsafe
def a3_done(mode, offset, term, next, stack):
  match stack:
    case Nil{}:
      FFresh{term, next}
    case Con{frame, rest}:
      a3_resume(mode, offset, term, next, frame, rest)

@unsafe
def a3_resume(mode, offset, term, next, frame, stack):
  match frame:
    case A3Frame{root, outer, inner, shape, pending, built, +field}:
      a3_kids(mode, offset, root, outer, inner, shape, pending, Con{kc(KTerm, String.eq(tg(field), "Bind"), u => kt("Bind", nm(field), ix(field), qt(field), [term]), u => term), built}, next, stack)

@unsafe
def a3_fresh(
  +term: KTerm,
  +env: List<&2,KTerm>,
  +next: U32,
) -> FFresh:
  a3_walk(0, 0, term, env, next, Nil{})

@unsafe
def a3_unwrap(
  +result: FFresh,
) -> KTerm:
  match result:
    case FFresh{term, next}:
      term

@unsafe
def a3_shift(
  +term: KTerm,
  +offset: U32,
) -> KTerm:
  a3_unwrap(a3_walk(1, offset, term, Nil{}, 0, Nil{}))
