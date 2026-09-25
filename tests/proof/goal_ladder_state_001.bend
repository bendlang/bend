# goal ladder, mul_comm Z-arm state 1 (after the mul_zero rewrite):
# the residual closes by conversion.
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

law mul:
  for a: N
  for +b: N
  N

def mul(a, b):
  match a:
    case Z{}:
      Z{}
    case S{p}:
      add(b, mul(p, b))

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
      %add_succ(y, add(q, z)) : {S{add(q, add(y, z))} == _ : N}
      %add_swap(q, y, z) : {S{add(q, add(y, z))} == S{_} : N}
      {==}

law mul_zero:
  for a: N
  {mul(a, Z{}) == Z{} : N}

def mul_zero(a):
  match a:
    case Z{}:
      {==}
    case S{p}:
      mul_zero(p)

law mul_succ:
  for +a: N
  for +b: N
  {add(a, mul(a, b)) == mul(a, S{b}) : N}

def mul_succ(a, b):
  match a:
    case Z{}:
      {==}
    case S{p}:
      %mul_succ(p, b) : {S{add(p, add(b, mul(p, b)))} == S{add(b, _)} : N}
      %add_swap(p, b, mul(p, b)) : {S{add(p, add(b, mul(p, b)))} == S{_} : N}
      {==}

law mul_comm:
  for +a: N
  for +b: N
  {mul(a, b) == mul(b, a) : N}

def mul_comm(a, b):
  match a:
    case Z{}:
      %mul_zero(b) : {_ == mul(b, Z{}) : N}
      Type
    case S{p}:
      %mul_succ(b, p) : {add(b, mul(p, b)) == _ : N}
      %mul_comm(p, b) : {add(b, mul(p, b)) == add(b, _) : N}
      {==}

#|Error:
#|- expected : {mul(b, Z{}) == mul(b, Z{}) : N}
#|- observed : Type
#|Context:
#|- b : N
#|Location: mul_comm
#|95 |       %mul_zero(b) : {_ == mul(b, Z{}) : N}
#|96>|       Type
#|   |       ^^^^
#|97 |     case S{p}:
#|exit 1
