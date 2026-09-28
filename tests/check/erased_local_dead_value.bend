# a - local is erased: its value is checked at demand -, so it may spend
# a variable twice. body_flatten once joined the local's - with its
# pattern's 1, which yielded 1 and measured the value live
import Base

def g(x: Nat, f: Nat -> Nat) -> Nat:
  -y = f(f(x))
  0n

#|ALL PROOFS CHECK
#|Use --verdict for mathematical validity.
