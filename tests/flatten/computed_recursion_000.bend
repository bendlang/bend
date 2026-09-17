# recursion under the lambda-match-application ban: the deep decision
# is spelled structurally on the scrutinee itself -- a computed match
# would be the banned form
# ported from bend3: literal arm values become ctors; the fuel rides a
# Nat matched ahead of the descent (the queens shape)
import Base

type Nt is Data:
  Zn{}
  Sn{p: Nt}

type Bl is Data:
  T{}
  F{}

type W is Data:
  Z{}
  S{p: W}

law big:
  for a: Nt
  Bl

def big(a):
  match a:
    case Zn{}:
      F{}
    case Sn{Zn{}}:
      F{}
    case Sn{Sn{p}}:
      T{}

law main:
  for  f: Nat
  for +n: Nt
  W

def main(f, n):
  match f:
    case 0n:
      Z{}
    case 1n+g:
      match n:
        case Zn{}:
          Z{}
        case Sn{Zn{}}:
          Z{}
        case Sn{Sn{p}}:
          S{S{main(g, p)}}

#|\{Zero: (n => Z{}); Succ: (g => \{Zn: Z{}; Sn: \{Zn: Z{}; Sn: (p => S{S{main(g, p)}})}})}
