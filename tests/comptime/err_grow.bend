# a self-call whose compile-time argument grows one node per level never
# reaches a shared instance: past the key wall (32768 chars) the parser
# refuses the call, at the call
import Base

def inc(n: Nat) -> Nat:
  1n+n

def grow(~f: Nat -> Nat, x: Nat) -> Nat:
  match x:
    case 0n:
      f(0n)
    case 1n+p:
      grow(~(y => inc(f(y))), p)

def main() -> Nat:
  grow(~inc, 2n)

#|Error:
#|- expected : a ~ argument that stops growing (32768 key chars at most)
#|- observed : grow
#|Location:
#|13 |     case 1n+p:
#|14>|       grow(~(y => inc(f(y))), p)
#|15 | 
#|exit 1
