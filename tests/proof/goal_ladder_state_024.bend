# goal ladder, ack 1n+p/0n state: ack steps into its second equation.
# ported from bend3: the ladder rides the ported bend development, so
# the pinned page is bend's own goal at the same proof state
import Base

law LE:
  for a: Nat
  for b: Nat
  Type

def LE(a, b):
  match a:
    case 0n:
      Unit
    case 1n+a1:
      match b:
        case 0n:
          Empty
        case 1n+b1:
          LE(a1, b1)

law ack:
  for +m: Nat
  for +n: Nat
  Nat

def ack(m, n):
  match m:
    case 0n:
      1n+n
    case 1n+p:
      match n:
        case 0n:
          ack(p, 1n)
        case 1n+q:
          ack(p, ack(1n+p, q))

law le_refl:
  for n: Nat
  LE(n, n)

def le_refl(n):
  match n:
    case 0n:
      Unit{}
    case 1n+p:
      le_refl(p)

law le_widen:
  for a: Nat
  for b: Nat
  for e: LE(a, b)
  LE(a, 1n+b)

def le_widen(a, b, e):
  match a:
    case 0n:
      Unit{}
    case 1n+c:
      match b:
        case 0n:
          match e:
        case 1n+d:
          le_widen(c, d, e)

law le_unstep:
  for a: Nat
  for b: Nat
  for e: LE(1n+a, b)
  LE(a, b)

def le_unstep(a, b, e):
  match b:
    case 0n:
      match e:
    case 1n+c:
      le_widen(a, c, e)

law le_trans:
  for a: Nat
  for b: Nat
  for c: Nat
  for e1: LE(a, b)
  for e2: LE(b, c)
  LE(a, c)

def le_trans(a, b, c, e1, e2):
  match a:
    case 0n:
      Unit{}
    case 1n+a1:
      match b:
        case 0n:
          match e1:
        case 1n+b1:
          match c:
            case 0n:
              match e2:
            case 1n+c1:
              le_trans(a1, b1, c1, e1, e2)

law ack_gt:
  for +m: Nat
  for +n: Nat
  LE(1n+n, ack(m, n))

def ack_gt(m, n):
  match m:
    case 0n:
      le_refl(1n+n)
    case 1n+p:
      match n:
        case 0n:
          Type
        case 1n+q:
          le_trans(2n+q, 1n+ack(1n+p, q), ack(p, ack(1n+p, q)), ack_gt(1n+p, q), ack_gt(p, ack(1n+p, q)))

#|Error:
#|- expected : LE(1n, ack(p, 1n))
#|- observed : Type
#|Context:
#|- p : Nat
#|Location: ack_gt
#|113 |         case 0n:
#|114>|           Type
#|115 |         case 1n+q:
#|exit 1
