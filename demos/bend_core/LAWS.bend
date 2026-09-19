import Base
import ./main.bend as Core

# The three weak-head reduction rules represented by this fragment.
law annotation_step:
  for fuel: Nat
  for book: List<&2, Core.Def>
  for term: Core.Term
  for ty: Core.Term
  {Core.run(1n+fuel, book, Core.TAnn{term, ty}) == Core.run(fuel, book, term) : Core.WHResult}

law let_step:
  for fuel: Nat
  for book: List<&2, Core.Def>
  for value: Core.Term
  for body: Core.Term
  {Core.run(1n+fuel, book, Core.TLet{value, body}) == Core.run(fuel, book, Core.subst(body, 0n, value)) : Core.WHResult}

law beta_step:
  for fuel: Nat
  for book: List<&2, Core.Def>
  for body: Core.Term
  for arg: Core.Term
  {Core.run(1n+1n+fuel, book, Core.TApp{Core.TLam{body}, arg}) == Core.run(fuel, book, Core.subst(body, 0n, arg)) : Core.WHResult}
