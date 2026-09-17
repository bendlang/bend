# nested computed decisions (one probe per level) move to one worker
# def matching both probes; the shared word wears + and feeds both
# probes at the call (an applied match-lambda is a banned form)
# ported from bend3: numeric columns become ctor columns, literal arm
# values become ctors
import Base
type Bl is Data:
  T{}
  F{}

type W is Data:
  Z{}
  S{p: W}

type R is Data:
  K1{}
  K2{}
  K3{}

law pos:
  for a: W
  Bl

def pos(a):
  match a:
    case Z{}:
      F{}
    case n:
      T{}

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

law main:
  for z1: Bl
  for z2: Bl
  R

def main(z1, z2):
  match z1:
    case T{}:
      match z2:
        case T{}:
          K1{}
        case F{}:
          K2{}
    case F{}:
      K3{}

#|\{T: \{T: K1{}; F: K2{}}; F: (z2 => K3{})}
