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

law main.dec:
  for r  : W
  for z1 : Bl
  for z2 : Bl
  W

def main.dec(r, z1, z2):
  match z1:
    case T{}:
      match z2:
        case T{}:
          S{r}
        case F{}:
          Z{}
    case F{}:
      r

law main:
  for f: Nat
  for n: W
  W

def main(f, n):
  match f:
    case 0n:
      Z{}
    case 1n+g:
      match n:
        case Z{}:
          Z{}
        case S{m0}:
          +m = {m0 : W}
          main.dec(main(g, m), par(m), par(m))

#|\{Zero: (n => Z{}); Succ: (g => \{Z: Z{}; S: (m0 => main.dec(main(g, m0), par(m0), par(m0)))})}
