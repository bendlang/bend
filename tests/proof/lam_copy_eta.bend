# a λ that copies its variable goes to BendTT as a λ+, and converts with
# the plain λ of the η-long abstract f it is compared with, under a call
# stuck on m: the kernel compares λs by liveness, not by quantity
import Base

def apply(m: Maybe<&2, Nat>, f: Nat -> Nat) -> Nat:
  match m:
    case None{}: 0n
    case Some{n}: f(n)

def twice(m: Maybe<&2, Nat>) -> Nat:
  apply(m, +a => Nat.add(a, a))

def once(m: Maybe<&2, Nat>) -> Nat:
  apply(m, a => Nat.add(a, 1n))

def same(m: Maybe<&2, Nat>, -f: Nat -> Nat, -g: Maybe<&2, Nat> -> Nat, e: {apply(m, f) == g(m) : Nat}) -> Unit:
  Unit{}

def t2(+m: Maybe<&2, Nat>) -> Unit:
  same(m, +a => Nat.add(a, a), twice, {==})

def t1(+m: Maybe<&2, Nat>) -> Unit:
  same(m, a => Nat.add(a, 1n), once, {==})

#|ALL PROOFS CHECK
#|Use --verdict for mathematical validity.
