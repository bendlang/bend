# a computed decision nested under a constructor case moves to a
# worker def matching a Bl parameter (an applied match-lambda is a
# banned form)
# ported from bend3: literal arm values become ctors
type Nt is Data:
  Zn{}
  Sn{p: Nt}

type Bl is Data:
  T{}
  F{}

type R is Data:
  K5{}
  K6{}
  K7{}

law zro:
  for a: Nt
  Bl

def zro(a):
  match a:
    case Zn{}:
      T{}
    case Sn{p}:
      F{}

law dec:
  for z: Bl
  R

def dec(z):
  match z:
    case T{}:
      K6{}
    case F{}:
      K7{}

law main:
  for n: Nt
  R

def main(n):
  match n:
    case Zn{}:
      K5{}
    case Sn{p}:
      dec(zro(p))

#|\{Zn: K5{}; Sn: (p => dec(zro(p)))}
