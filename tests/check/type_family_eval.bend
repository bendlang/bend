# type families: a match computing a Type, and a maker whose match
# motive refines the family per arm -- the value normalizes whole.
# ported from bend3: bend evaluates main only, so the value block is
# the pin (the TYPE normal form has no CLI surface)
import Base

type Nk is Data:
  Zk{}
  Sk{p: Nk}

law Rep:
  for n: Nk
  Type

def Rep(n):
  match n:
    case Zk{}:
      U32
    case Sk{p}:
      U32 & Rep(p)

law make:
  for n: Nk
  Rep(n)

def make(n):
  match n:
    case Zk{}:
      7
    case Sk{p}:
      (1, make(p))

law main:
  Rep(Sk{Sk{Zk{}}})

def main(): make(Sk{Sk{Zk{}}})

#|(1, 1, 7)
