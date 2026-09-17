# mixed group in argument order: a and b fuse as pattern columns, the
# computed main(b) feeds a helper's unused third param (bend's match
# takes bare scrutinees; the kept b wears +)
# ported from bend3: literal arm values become ctors
import Base
type Nt is Data:
  Zn{}
  Sn{p: Nt}

type W is Data:
  Z{}
  S{p: W}

law main:
  for n: Nt
  Nt

def main(n):
  n

law sel:
  for a: Nt
  for b: Nt
  for w: Nt
  W

def sel(a, b, w):
  match a, b:
    case Zn{}, Zn{}:
      Z{}
    case Zn{}, Sn{q}:
      S{Z{}}
    case Sn{p}, x:
      S{S{Z{}}}

#|n => n
