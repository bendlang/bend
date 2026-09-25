# the descent verdict inside one constructor column is not
# lexicographic: fields compare left to right and every non-EQ result
# overwrites the verdict, so a later growing field overrules an earlier
# shrinking one (LT then GT is GT) and the self-call refuses. pins the
# law against a lax first-non-EQ respelling, which accepts this program
# whole.
import Base

type PairN is Data:
  MkP{fst: Nat, snd: Nat}

law wob:
  for p: PairN
  Nat

def wob(p):
  match p:
    case MkP{Zero{}, b}:
      b
    case MkP{Succ{a2}, b}:
      wob(MkP{a2, Succ{b}})

law main:
  Nat

def main(): wob(MkP{2n, 0n})

#|Error:
#|- expected : a decreasing self-call (arguments are read left to right: each passed unchanged until one shrinks)
#|- observed : wob
#|Context:
#|- a2 : Nat
#|- b  : Nat
#|Location: wob
#|20 |     case MkP{Succ{a2}, b}:
#|21>|       wob(MkP{a2, Succ{b}})
#|   |       ^^^
#|22 |
#|exit 1
