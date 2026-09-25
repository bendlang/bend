# goal ladder, Ford elimination ESS-arm: goal Emp, eq refined to
# {S{Z{}} == S{S{p}}}.
# ported from bend3: the ladder rides the ported bend development, so
# the pinned page is bend's own goal at the same proof state
type Uni is Data:
  U{}
type Emp is Data:

type N is Data:
  Z{}
  S{p: N}

type Even<-n: N> is Data:
  EZ{eq: {n == Z{} : N}}
  ESS{p: N, e: Even<p>, eq: {n == S{S{p}} : N}}

law NatD:
  for x: N
  for zc: Type
  for sc: Type
  Type

def NatD(x, zc, sc):
  match x:
    case Z{}:
      zc
    case S{q}:
      sc

law refute_ez:
  for eq: {S{Z{}} == Z{} : N}
  Emp

def refute_ez(eq):
  %eq : NatD(_, Emp, Uni)
  U{}

law one_odd:
  for ev: Even<S{Z{}}>
  Emp

def one_odd(ev):
  match ev:
    case EZ{eq}:
      refute_ez(eq)
    case ESS{p, e, eq}:
      Type

#|Error:
#|- expected : Emp
#|- observed : Type
#|Context:
#|- p  : N
#|- e  : Even<p>
#|- eq : {S{Z{}} == S{S{p}} : N}
#|Location: one_odd
#|46 |     case ESS{p, e, eq}:
#|47>|       Type
#|   |       ^^^^
#|48 |
#|exit 1
