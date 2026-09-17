# nested computed decisions move to one worker def matching both
# probes (the helper holds the default row); the shared word wears +
# and feeds both probes at the call site
# ported from bend3: numeric columns become ctor columns, the n < 5
# comparison becomes a structural test, the shared word wears +
import Base
type Bl is Data:
  T{}
  F{}

type W is Data:
  Z{}
  S{p: W}

type R is Data:
  K1{}
  K500{}
  K50{}

law not:
  for a: Bl
  Bl

def not(a):
  match a:
    case T{}:
      F{}
    case F{}:
      T{}

law odd:
  for a: W
  Bl

def odd(a):
  match a:
    case Z{}:
      F{}
    case S{n}:
      not(odd(n))

law small:
  for x: W
  Bl

def small(x):
  match x:
    case Z{}:
      T{}
    case k:
      F{}

law main:
  for z1: Bl
  for z2: Bl
  R

def main(z1, z2):
  match z1:
    case T{}:
      K1{}
    case F{}:
      match z2:
        case T{}:
          K50{}
        case F{}:
          K500{}

#|\{T: (z2 => K1{}); F: \{T: K50{}; F: K500{}}}
