# goal ladder, le_bump impossible-arm state: at r=d1=0n the eq
# hypothesis is {True{} == False{}} and the goal is Empty; the whole
# development descends structurally, so the ladder rides strict.
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

law eqn:
  for a: Nat
  for b: Nat
  Bool

def eqn(a, b):
  match a, b:
    case 0n, 0n:
      True{}
    case 0n, 1n+bp:
      False{}
    case 1n+ap, 0n:
      False{}
    case 1n+ap, 1n+bp:
      eqn(ap, bp)

law le_bump:
  for r: Nat
  for d1: Nat
  for ev: LE(r, d1)
  for e: {eqn(r, d1) == False{} : Bool}
  LE(1n+r, d1)

def le_bump(r, d1, ev, e):
  match r, d1:
    case 0n, 0n:
      Type
    case 0n, 1n+b:
      Unit{}
    case 1n+a, 0n:
      match ev:
    case 1n+a, 1n+b:
      le_bump(a, b, ev, e)

#|Error:
#|- expected : Empty
#|- observed : Type
#|Context:
#|- ev : Unit
#|- e  : {True{} == False{} : Bool}
#|Location: le_bump
#|49 |     case 0n, 0n:
#|50>|       Type
#|51 |     case 0n, 1n+b:
#|exit 1
