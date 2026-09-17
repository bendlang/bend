# %x@e : P is the explicit-motive rewrite (the J axiom): the motive
# binds _ (the second endpoint) and x (the equation); the body follows
# on its own line or the same one.
# ported from bend3: the real-lambda motive `x => P` becomes bend's
# _-bound motive term, S/Z ride the test's own N
import Base

type N is Data:
  Z{}
  S{p: N}

law pred:
  for n: N
  N

def pred(n):
  match n:
    case Z{}:
      Z{}
    case S{p}:
      p

law succ_inj:
  for a: N
  for b: N
  for e: {S{a} == S{b} : N}
  {a == b : N}

def succ_inj(a, b, e):
  %x@e : {pred(S{a}) == pred(_) : N}
  {==}

law sym:
  @-x:N -> @-y:N -> {x == y : N} -> {y == x : N}

def sym(): x => y => e => %h@e : {_ == x : N}; {==}

law main.out:
  Nat

def main.out(): 0n

law main:
  IO(Unit)

def main():
  IO.print(String.append(Nat.show(main.out()), "n"))

#|0n
