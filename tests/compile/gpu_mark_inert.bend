# bend3's zero-semantics mark: f!(x) is f(x) to checker and evaluator,
# and marks in a parallel let ride as plain calls. bend's bang
# carries the same law through its fork-let; the generic
# pick!(x, y) half is gone with def<A> (ruled out, collides with
# infix <). Countdowns ride +Nat (the fork re-uses its pred; Nat is
# Data), f's pred re-use a +U32 mirror
import Base

law f:
  for  n: Nat
  for +i: U32
  U32

def f(n, i):
  match n:
    case Zero{}:
      1
    case Succ{k}:
      (f(k, (i - 1 : U32)) + i : U32)

law g:
  for +d: Nat
  U32

def g(d):
  match d:
    case Zero{}:
      f(3n, 3)
    case Succ{k}:
      a b = g!(k) g(k)
      (a + b : U32)

law main.out:
  Nat

def main.out():
  U32.to_nat(g(2n))

law main:
  IO(Unit)

def main():
  IO.print(String.append(Nat.show(main.out()), "n"))

#|28n
