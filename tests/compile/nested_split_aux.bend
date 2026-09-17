# recursion through nested checker-minted split auxes: a value matched
# via a computed group, the inner group rebinding it through a typed
# local, the pattern Sc{Sc{p}} feeding the recursive call
# ported from bend3: the shared scrutinee becomes a +param (Nt is
# Data), and the recursion rides a Nat fuel
# matched ahead of the group (the queens shape): the aux chain hides
# the shrinking column, the fuel is the one the descent sees
import Base

type Nt is Data:
  Zr{}
  Sc{p: Nt}

type Bl is Data:
  Tt{}
  Ff{}

law big:
  for a: Nt
  Bl

def big(a):
  match a:
    case Zr{}:
      Ff{}
    case Sc{Zr{}}:
      Ff{}
    case Sc{Sc{p}}:
      Tt{}

law cnt.go:
  for  f: Nat
  for  t: Bl
  for +n: Nt
  U32

def cnt.go(f, t, n):
  match f:
    case 0n:
      0
    case 1n+g:
      match t:
        case Tt{}:
          match n:
            case Sc{Sc{p}}:
              U32.add(2, cnt.go(g, big(p), p))
            case Sc{Zr{}}:
              1
            case Zr{}:
              1
        case Ff{}:
          0

law cnt:
  for  f: Nat
  for +n: Nt
  U32

def cnt(f, n):
  cnt.go(f, big(n), n)

law main.out:
  U32

def main.out():
  n = {Sc{Sc{Sc{Zr{}}}} : Nt}
  cnt(4n, n)

law main:
  IO(Unit)

def main():
  IO.print(U32.show(main.out()))

#|2
