# the growing self-call, doubling: the argument's key doubles per level,
# so the key wall (2048 chars) leaves the call plain at level 8 and the
# checker refuses the name there (an argument that grows only as a Nat
# literal prints short and escapes the wall: a host crash, no program accepted)
import Base

def inc(n: Nat) -> Nat:
  1n+n

def grow(~f: Nat -> Nat, x: Nat) -> Nat:
  match x:
    case 0n:
      f(0n)
    case 1n+p:
      grow(~(y => f(f(y))), p)

def main() -> Nat:
  grow(~inc, 2n)

#|Error:
#|- expected : a defined name
#|- observed : grow
#|Context:
#|- f : @_:Nat -> Nat
#|- p : Nat
#|Location: grow~8
#|14 |     case 1n+p:
#|15>|       grow(~(y => f(f(y))), p)
#|16 |
#|exit 1
