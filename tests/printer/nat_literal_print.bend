# a nat literal prints back as a literal, a Succ chain that ends in a
# literal prints as one number, and "n + T" past 256 is Nat.add
import Base

def small(n: Nat) -> Nat:
  2n+n

def big(n: Nat) -> Nat:
  300n+n

def chain() -> Nat:
  Succ{Succ{300n}}

def main(a: Nat, b: Nat) -> Nat:
  Nat.add(small(a), Nat.add(big(b), Nat.add(chain(), 4294967295n)))

#|a => b => 2n+Nat.add(a, 300n+Nat.add(b, 4294967597n))
