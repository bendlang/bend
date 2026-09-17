# Vec ladder, complete: rewriting the index by add_zero transports v
# ported from bend3: the lemma is stated with add(n, 0n) on the RIGHT
# (bend's rewrite folds right into left) and takes explicit motives
import Base

law Vec:
  for n: Nat
  Type

def Vec(n):
  match n:
    case 0n:
      Unit
    case 1n+p:
      Nat & Vec(p)

law add_zero:
  for n: Nat
  {n == Nat.add(n, 0n) : Nat}

def add_zero(n):
  match n:
    case 0n:
      {==}
    case 1n+p:
      %add_zero(p) : {1n+p == 1n+_ : Nat}
      {==}

law vpad:
  for n: Nat
  for v: Vec(n)
  Vec(Nat.add(n, 0n))

def vpad(n, v):
  %add_zero(n) : Vec(_)
  v

#|All terms check.
