# a length-indexed vector as a type family: append's result type is
# Vec(add(n, m)), the family computing per induction step -- the
# dependent goal refines through the destructured head.
# ported from bend3: Nat payloads replace U32 so the printed vector
# stays literal; () becomes Unit{}
import Base

type N is Data:
  Z{}
  S{p: N}

law add:
  for a: N
  for b: N
  N

def add(a, b):
  match a:
    case Z{}:
      b
    case S{p}:
      S{add(p, b)}

law Vec:
  for n: N
  Type

def Vec(n):
  match n:
    case Z{}:
      Unit
    case S{p}:
      (Nat & Vec(p))

law vapp:
  for n  : N
  for -m : N
  for xs : Vec(n)
  for ys : Vec(m)
  Vec(add(n, m))

def vapp(n, m, xs, ys):
  match n:
    case Z{}:
      ys
    case S{p}:
      (h, t) = xs
      (h, vapp(p, m, t, ys))

law cat:
  Vec(add(S{S{Z{}}}, S{Z{}}))

def cat(): vapp(S{S{Z{}}}, S{Z{}}, (1n, (2n, Unit{})), (3n, Unit{}))

law main:
  Vec(add(S{S{Z{}}}, S{Z{}}))

def main(): cat()

#|(1n, 2n, 3n, Unit{})
