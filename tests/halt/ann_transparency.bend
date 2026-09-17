# bend3's halt checker looked through Ann on the self-call head; bend
# rejects an Ann-wrapped self-call by design (infer-app demands the
# bare Ref) -- the wrapped head refuses as an escaping self-reference
import Base

law head9:
  for n: Nat
  for x: U32
  U32

def head9(n, x):
  match n:
    case Zero{}:
      x
    case Succ{p}:
      (1 + {{head9 : Nat -> U32 -> U32}({p : Nat}) : U32 -> U32}({x : U32}) : U32)

law main:
  U32

def main():
  0

#|Error:
#|- expected : a decreasing self-call (arguments are read left to right: each passed unchanged until one shrinks)
#|- observed : head9
#|Context:
#|- p : Nat
#|- x : U32
#|Location: head9
#|15 |     case Succ{p}:
#|16>|       (1 + {{head9 : Nat -> U32 -> U32}({p : Nat}) : U32 -> U32}({x : U32}) : U32)
#|17 |
#|exit 1
