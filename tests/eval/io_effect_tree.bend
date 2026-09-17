# an effect tree spells each continuation as a trailing lambda; a
# contracted effect result (a, shared by a let in the continuation)
# threads through two later effects, and normalization dissolves the
# share of a variable: the residual tree prints whole.
# ported from bend3: the local IO type renames to Eff with fresh ctor
# names (bend ctors are global), payloads become Nat for a readable
# golden, the contraction takes a +Nat-annotated let (Cop)
import Base

type Eff is Type:
  EDone{value: Nat}
  EPrint{text: Nat, cont: @k:Nat -> Eff}

law put:
  @n:Nat -> @k:(@x:Nat -> Eff) -> Eff

def put():
  n => k => EPrint{n, k}

law cont:
  for a0: Nat
  Eff

def cont(a0):
  +a = {a0 : Nat}
  EPrint{Nat.add(a, 1n), b => put(Nat.add(a, b), v => EDone{v})}

law main:
  Eff

def main():
  EPrint{1n, a => cont(a)}

#|EPrint{1n, a => EPrint{Nat.add(a, 1n), b => EPrint{Nat.add(a, b), v => EDone{v}}}}
