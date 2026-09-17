# FLAGSHIP: Ackermann's lower bound n < ack(m, n), by the SAME
# lexicographic induction that certifies ack -- the nested IHs
# chain through le_trans; le_widen/le_unstep are the local LE kit.
# ported from bend3: bend3's Base Nat.LE/LT family becomes a local LE
# (LT(a, b) spelled LE(1n+a, b)); ack's shared binders ride +Nat
# Many scrutinees (Nat is Data)
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
  for a  : Nat
  for b  : Nat
  for c  : Nat
  for e1 : LE(a, b)
  for e2 : LE(b, c)
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
          le_unstep(1n, ack(p, 1n), ack_gt(p, 1n))
        case 1n+q:
          le_trans(2n+q, 1n+ack(1n+p, q), ack(p, ack(1n+p, q)), ack_gt(1n+p, q), ack_gt(p, ack(1n+p, q)))

#|All terms check.
