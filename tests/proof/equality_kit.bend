# Base Equal (the equality kit over the primitive {a == b : T}):
# sym flips, trans chains, cong maps -- each usable with hypothesis
# ARGUMENTS (e : {a == b : T} params) and on concretes, where the
# proof computes to {==}.
# ported from bend3: bend's own base carries Equal.sym/trans/cong
import Base

law flip:
  for -x: Nat
  for  e: {x == 3n : Nat}
  {3n == x : Nat}

def flip(x, e):
  Equal.sym(Nat, x, 3n, e)

law chain:
  for -x : Nat
  for -y : Nat
  for e1 : {x == y : Nat}
  for e2 : {y == 5n : Nat}
  {x == 5n : Nat}

def chain(x, y, e1, e2):
  Equal.trans(Nat, x, y, 5n, e1, e2)

law succ_eq:
  for -x: Nat
  for -y: Nat
  for  e: {x == y : Nat}
  {Succ{x} == Succ{y} : Nat}

def succ_eq(x, y, e):
  Equal.cong(Nat, Nat, n => Succ{n}, x, y, e)

law v:
  {3n == Nat.add(1n, 2n) : Nat}

def v(): Equal.sym(Nat, Nat.add(1n, 2n), 3n, {==})

law main:
  {3n == Nat.add(1n, 2n) : Nat}

def main(): v()

#|{==}
