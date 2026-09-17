# computed scrutinee, ref call: the decision moves to a worker def
# and f(n) rides in the call's argument position (an applied
# match-lambda is a banned form)
# ported from bend3: literal arm values become ctors
type Nt is Data:
  Zn{}
  Sn{p: Nt}

type Bl is Data:
  T{}
  F{}

type W is Data:
  Z{}
  S{p: W}

law f:
  for n: Nt
  Bl

def f(n):
  match n:
    case Zn{}:
      T{}
    case Sn{p}:
      F{}

law step:
  for z: Bl
  W

def step(z):
  match z:
    case T{}:
      S{Z{}}
    case F{}:
      Z{}

law main:
  for n: Nt
  W

def main(n):
  step(f(n))

#|n => step(f(n))
