# TWO exists clauses nest sigmas, and the fill's witness is the
# right-nested tuple -- (1n, 2n, {==}) is (1n, (2n, {==})).
# ported from bend3: Nat witnesses replace U32 so the printed value
# stays literal; main spells the folded sigma type and returns the fill
import Base

law two_wit:
  exs a: Nat
  exs b: Nat
  {Nat.add(a, b) == 3n : Nat}

def two_wit():
  (1n, 2n, {==})

law main:
  Sigma<&1, &1, Nat, a => Sigma<&1, &1, Nat, b => {Nat.add(a, b) == 3n : Nat}>>

def main(): two_wit()

#|(1n, 2n, {==})
