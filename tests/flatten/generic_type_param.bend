# bend3's def<A,B> generics and f<A>(x) call sugar; bend TYPES take
# <> parameters (P6 below is legal) but defs never do -- def generics
# are ruled out (they collide with infix <), and the decl head dies
# at its '<'
import Base

type P6<-A: Type, -B: Type> is Type:
  MkP6{fst: A, snd: B}

law swap:
  for -A: Type
  for -B: Type
  for p: P6(A, B)
  P6(B, A)

def swap<A, B>(p):
  match p:
    case MkP6{x, y}:
      MkP6{y, x}

law main:
  U32

def main():
  0

#|Error:
#|- expected : '('
#|- observed : '<'
#|Location:
#|15 | 
#|16>| def swap<A, B>(p):
#|17 |   match p:
#|exit 1
