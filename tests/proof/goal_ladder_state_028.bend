# goal ladder, half_exists S{S{p}}-arm: the sigma goal at the
# destructured witness.
# ported from bend3: the ladder rides the ported bend development, so
# the pinned page is bend's own goal at the same proof state
import Base

type N is Data:
  Z{}
  S{p: N}

law double:
  for n: N
  N

def double(n):
  match n:
    case Z{}:
      Z{}
    case S{p}:
      S{S{double(p)}}

law IsEven:
  for n: N
  Type

def IsEven(n):
  match n:
    case Z{}:
      Unit
    case S{Z{}}:
      Empty
    case S{S{p}}:
      IsEven(p)

law half_exists:
  for x: N
  for e: IsEven(x)
  exs y: N
  {double(y) == x : N}

def half_exists(x, e):
  match x:
    case Z{}:
      (Z{}, {==})
    case S{Z{}}:
      match e:
    case S{S{p}}:
      Type

#|Error:
#|- expected : Sigma<&1, &1, N, y => {double(y) == S{S{p}} : N}>
#|- observed : Type
#|Context:
#|- p : N
#|- e : IsEven(p)
#|Location: half_exists
#|47 |     case S{S{p}}:
#|48>|       Type
#|49 |
#|exit 1
