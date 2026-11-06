# copying the evaluated value instead of the stored one isn't enough:
# S{pr(c)} == c would set c := S{pr(c)}, so c's value would hold c, and
# {c == S{Z{}}} would unfold it forever
import Base

type N is Type:
  Z{}
  S{p: N}

def pr(n: N) -> N:
  match n:
    case Z{}:
      Z{}
    case S{p}:
      p

def P(c: N) -> Type:
  {S{pr(c)} == c : N} & {c == S{Z{}} : N}

def p() -> P(S{Z{}}):
  ({==}, {==})

#|ALL PROOFS CHECK
#|Use --verdict for mathematical validity.
