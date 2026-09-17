# three stacked computed scrutinees: the computed values feed a
# helper's columns in order
# ported from bend3: literal arm values become ctors
type Bl is Data:
  T{}
  F{}

type R is Data:
  K1{}
  K2{}
  K3{}
  K4{}

law main:
  for a: Bl
  Bl

def main(a):
  match a:
    case T{}:
      F{}
    case F{}:
      T{}

law sel:
  for a: Bl
  for b: Bl
  for c: Bl
  R

def sel(a, b, c):
  match a, b, c:
    case T{}, T{}, x:
      K1{}
    case T{}, F{}, x:
      K2{}
    case F{}, x, T{}:
      K3{}
    case F{}, x, F{}:
      K4{}

#|\{T: F{}; F: T{}}
