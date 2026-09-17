# goal ladder, add_swap S-arm state 0: LHS steps under S, RHS stuck.
# ported from bend3: the ladder rides the ported bend development, so
# the pinned page is bend's own goal at the same proof state
import Base
type N is Data:
  Z{}
  S{p: N}

law add:
  for a: N
  for b: N
  N

def add(a, b):
  match a:
    case Z{}:
      b
    case S{p}:
      S{add(p, b)}

law add_succ:
  for a: N
  for -b: N
  {S{add(a, b)} == add(a, S{b}) : N}

def add_succ(a, b):
  match a:
    case Z{}:
      {==}
    case S{p}:
      %add_succ(p, b) : {S{S{add(p, b)}} == S{_} : N}
      {==}

law add_swap:
  for +x: N
  for +y: N
  for +z: N
  {add(x, add(y, z)) == add(y, add(x, z)) : N}

def add_swap(x, y, z):
  match x:
    case Z{}:
      {==}
    case S{q}:
      Type

#|Error:
#|- expected : {S{add(q, add(y, z))} == add(y, S{add(q, z)}) : N}
#|- observed : Type
#|Context:
#|- q : N
#|- y : N
#|- z : N
#|Location: add_swap
#|44 |     case S{q}:
#|45>|       Type
#|46 |
#|exit 1
