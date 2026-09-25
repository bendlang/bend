# goal ladder, add_comm S-arm state 1 (after the add_succ rewrite).
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
      %add_zero(b) : {_ == add(b, Z{}) : N}
      {==}
    case S{p}:
      %add_succ(b, p) : {S{add(p, b)} == _ : N}
      Type

#|Error:
#|- expected : {S{add(p, b)} == S{add(b, p)} : N}
#|- observed : Type
#|Context:
#|- p : N
#|- b : N
#|Location: add_comm
#|57 |       %add_succ(b, p) : {S{add(p, b)} == _ : N}
#|58>|       Type
#|   |       ^^^^
#|59 |
#|exit 1
