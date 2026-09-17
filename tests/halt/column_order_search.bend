# bend3 SEARCHED column orders and accepted the swapped Ackermann;
# bend's descent law is fixed left-to-right and its match laws bind
# tighter still -- the swapped spelling dies at the nested match's
# binder order, before any search could exist
import Base

law ack:
  for n: Nat
  for m: Nat
  Nat

def ack(n, m):
  match m:
    case Zero{}:
      Succ{n}
    case Succ{p}:
      match n:
        case Zero{}:
          ack(1n, p)
        case Succ{q}:
          ack(ack(q, Succ{p}), p)

law main:
  Nat

def main():
  ack(3n, 2n)

#|Error:
#|- message  : match scrutinees in binder order (this variable is unbound, consumed, or out of order: reorder the match)
#|Location:
#|16 |     case Succ{p}:
#|17>|       match n:
#|18 |         case Zero{}:
#|exit 1
