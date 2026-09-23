# a template instance minted while a law it mentions is still open, then
# reused after the law's fill, where the law unfolds
import Base

law L:
  for n: Nat
  Type

def box(~k: Nat, x: L(k)) -> L(k):
  x

def use(x: L(1n)) -> L(1n):
  box(~1n, x)

def L(n):
  Nat

def use2(x: Nat) -> Nat:
  box(~1n, x)

def main() -> Nat:
  use2(7n)

#|7n
