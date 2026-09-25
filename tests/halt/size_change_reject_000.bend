# size-change reject side carries: TWO call sites whose descents
# disagree -- one shrinks a while growing b, the other the reverse --
# and go(1n, 1n) really cycles. bend's left-to-right law refuses the
# first site outright: column a is refined to Z{} there, and S{Z{}}
# is no subterm of it.
# ported from bend3: bare ctors S/Z (base owns Succ/Zero), Nat sugar
# stays on the base Nat only
type N is Data:
  S{p: N}
  Z{}

law go:
  for a: N
  for b: N
  N

def go(a, b):
  match a:
    case Z{}:
      match b:
        case Z{}:
          Z{}
        case S{q}:
          go(S{Z{}}, q)
    case S{p}:
      match b:
        case Z{}:
          Z{}
        case S{q}:
          go(p, S{S{q}})

law main:
  N

def main(): go(S{Z{}}, S{Z{}})

#|Error:
#|- expected : a decreasing self-call (arguments are read left to right: each passed unchanged until one shrinks)
#|- observed : go
#|Context:
#|- q : N
#|Location: go
#|23 |         case S{q}:
#|24>|           go(S{Z{}}, q)
#|   |           ^^
#|25 |     case S{p}:
#|exit 1
