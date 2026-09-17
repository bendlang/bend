# self recursion into a datatype group (fold-then-inspect): the
# computed decision moves to a worker def that takes the recursive
# result as a parameter (an applied match-lambda is a banned form)
type Nt is Data:
  Zn{}
  Sn{p: Nt}

type Bl is Data:
  T{}
  F{}

law main:
  for z: Bl
  Bl

def main(z):
  match z:
    case T{}:
      F{}
    case F{}:
      T{}

#|\{T: F{}; F: T{}}
