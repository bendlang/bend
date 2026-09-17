# recursion under nested computed decisions: the decisions move to a
# worker def taking the recursive result and both par probes as
# parameters, and the shared word rebinds through a + local
# ({m0 : W}, W is Data; a match-lambda arm binder stays Lone, so the
# arm spells its own +)
# ported from bend3: the numeric columns become ctor columns; the
# recursion rides a Nat fuel matched ahead of the decisions (the
# queens shape)
import Base

type Bl is Data:
  T{}
  F{}

type W is Data:
  Z{}
  S{p: W}

law not:
  for a: Bl
  Bl

def not(a):
  match a:
    case T{}:
      F{}
    case F{}:
      T{}

law par:
  for a: W
  Bl

def par(a):
  match a:
    case Z{}:
      T{}
    case S{n}:
      not(par(n))

law main:
  for r  : W
  for z1 : Bl
  for z2 : Bl
  W

def main(r, z1, z2):
  match z1:
    case T{}:
      match z2:
        case T{}:
          S{r}
        case F{}:
          Z{}
    case F{}:
      r

#|r => \{T: \{T: S{r}; F: Z{}}; F: (z2 => r)}
