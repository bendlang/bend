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

law main:
  for a: Nt
  Bl

def main(a):
  match a:
    case Zn{}:
      F{}
    case Sn{Zn{}}:
      F{}
    case Sn{Sn{p}}:
      T{}

#|\{Zn: F{}; Sn: \{Zn: F{}; Sn: (p => T{})}}
