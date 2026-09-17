# bend3's `match x as e:` bound the split equation per arm; bend has
# no as binder -- the words read as extra scrutinees and the arm's
# pattern count refuses, before any equation exists
import Base

law use:
  for x: Nat
  for h: {x == Zero{} : Nat}
  {x == Zero{} : Nat}

def use(x, h):
  match x as e:
    case Zero{}:
      h
    case Succ{p}:
      h

law main:
  U32

def main():
  0

#|Error:
#|- expected : 3 patterns (one per scrutinee)
#|- observed : '
#|'
#|Location:
#|12 |   match x as e:
#|13>|     case Zero{}:
#|14 |       h
#|exit 1
