# bend3's FORWARD references: the scrutinee head and the type declared
# after use (forward ctor tags took qualification there); bend's
# parse-time ctor map is declare-before-use with no qualification, so
# the forward tag pins bend's own refusal
type Bl is Data:
  T{}
  F{}

law main:
  for n: Nt
  Bl

def main(n):
  match n:
    case Zn{}:
      T{}
    case Sn{p}:
      \{T: F{}; F: T{}}(g(p))

law g:
  for a: Nt
  Bl

def g(a):
  match a:
    case Zn{}:
      F{}
    case Sn{p}:
      main(p)

type Nt is Data:
  Zn{}
  Sn{p: Nt}

#|Error:
#|- message  : a declared constructor (unknown: Zn)
#|Location:
#|14 |   match n:
#|15>|     case Zn{}:
#|   |          ^^^^
#|16 |       T{}
#|exit 1
