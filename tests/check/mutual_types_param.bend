# three parametric families share their parameters and name each other
# in a cycle; a forward D<..> spells every parameter (the parser fills an
# omitted quantity only for a family it has seen)
import Base

type Term<a, -A: Kind(a)> is Kind(a):
  Var{name: A}
  Mat{scrut: Term<a, A>, arms: Arms<a, A>}

type Arms<a, -A: Kind(a)> is Kind(a):
  ANil{}
  ACon{head: Arm<a, A>, tail: Arms<a, A>}

type Arm<a, -A: Kind(a)> is Kind(a):
  Arm{ctr: A, body: Term<a, A>}

def Arms.len(-A: Type, xs: Arms<A>) -> U32:
  match xs:
    case ANil{}:
      0
    case ACon{x, rest}:
      (1 + Arms.len(A, rest) : U32)

def main() -> U32:
  Arms.len(U32, ACon{Arm{1, Var{2}}, ACon{Arm{3, Mat{Var{4}, ANil{}}}, ANil{}}})

#|2
