# goal ladder, Ford elimination EZ-arm: goal Emp with the eq field
# specialized to {S{Z{}} == Z{}}.
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

law one_odd:
  for ev: Even<S{Z{}}>
  Emp

def one_odd(ev):
  match ev:
    case EZ{eq}:
      Type
    case ESS{p, e, eq}:
      Type

#|Error:
#|- expected : Emp
#|- observed : Type
#|Context:
#|- eq : {S{Z{}} == Z{} : N}
#|Location: one_odd
#|23 |     case EZ{eq}:
#|24>|       Type
#|25 |     case ESS{p, e, eq}:
#|exit 1
