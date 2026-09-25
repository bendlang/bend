# a def parameter as a ~ argument: the argument checks in the empty
# context, where k is unbound, and the call is refused by name, with the
# repair (pass k at run time)
import Base

def T(~n: Nat, x: Nat) -> Nat:
  Nat.add(n, x)

def caller(k: Nat, x: Nat) -> Nat:
  T(~k, x)

def main() -> Nat:
  caller(1n, 2n)

#|Error:
#|- expected : a template applied to closed ~ arguments (k is a variable here, not comptime: pass it at run time)
#|- observed : T
#|Context:
#|- k : Nat
#|- x : Nat
#|Location: caller
#| 9 | def caller(k: Nat, x: Nat) -> Nat:
#|10>|   T(~k, x)
#|   |   ^
#|11 |
#|exit 1
