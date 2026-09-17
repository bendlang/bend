# self recursion into a datatype group (fold-then-inspect): the
# computed decision moves to a worker def that takes the recursive
# result as a parameter (an applied match-lambda is a banned form)
type Nt is Data:
  Zn{}
  Sn{p: Nt}

type Bl is Data:
  T{}
  F{}

law flip:
  for z: Bl
  Bl

def flip(z):
  match z:
    case T{}:
      F{}
    case F{}:
      T{}

law main:
  for n: Nt
  Bl

def main(n):
  match n:
    case Zn{}:
      T{}
    case Sn{p}:
      flip(main(p))

#|\{Zn: T{}; Sn: (p => flip(main(p)))}
