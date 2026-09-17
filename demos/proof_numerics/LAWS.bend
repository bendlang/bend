# proof_numerics: the laws. The human states them; PROOF.bend must
# prove them. A parameter is + when a proof spends it twice.

import Base
import ./main.bend as Num

# LAW: add is commutative
law add_comm:
  for  a: Nat
  for +b: Nat
  {Num.add(a, b) == Num.add(b, a) : Nat}

# LAW: add is associative
law add_assoc:
  for  a: Nat
  for -b: Nat
  for -c: Nat
  {Num.add(a, Num.add(b, c)) == Num.add(Num.add(a, b), c) : Nat}

# LAW: mul is commutative
law mul_comm:
  for +a: Nat
  for +b: Nat
  {Num.mul(a, b) == Num.mul(b, a) : Nat}

# LAW: mul distributes over add: (a + b) * c is a * c + b * c
law mul_dist:
  for  a: Nat
  for -b: Nat
  for +c: Nat
  {Num.add(Num.mul(a, c), Num.mul(b, c)) == Num.mul(Num.add(a, b), c) : Nat}

# LAW: divmod is Euclid's division: dividing n by 1n+m gives a
# quotient q and a remainder r below the divisor with n == r + q * (1n+m)
law divmod_ok:
  for +n: Nat
  for +m: Nat
  exs  q: Nat
  exs  r: Nat
  {(q, r) == Num.divmod(n, 1n+m) : Nat & Nat} & {True{} == (r < 1n+m) : Bool} & {n == Num.add(r, Num.mul(q, 1n+m)) : Nat}
