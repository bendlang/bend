# goal ladder, add_comm Z-arm state 0.
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

law add_zero:
  for a: N
  {add(a, Z{}) == a : N}

def add_zero(a):
  match a:
    case Z{}:
      {==}
    case S{p}:
      %add_zero(p) : {S{add(p, Z{})} == S{_} : N}
      {==}

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

law add_comm:
  for +a: N
  for +b: N
  {add(a, b) == add(b, a) : N}

def add_comm(a, b):
  match a:
    case Z{}:
      Type
    case S{p}:
      %add_succ(b, p) : {S{add(p, b)} == _ : N}
      %add_comm(p, b) : {S{add(p, b)} == S{_} : N}
      {==}

#|Error:
#|- expected : {b == add(b, Z{}) : N}
#|- observed : Type
#|Context:
#|- b : N
#|Location: add_comm
#|53 |     case Z{}:
#|54>|       Type
#|   |       ^^^^
#|55 |     case S{p}:
#|exit 1
