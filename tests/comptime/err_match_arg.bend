# a match-bound field as a ~ argument: a variable of the context like a
# parameter, so the call is refused by name
import Base

def T(~n: Nat, x: Nat) -> Nat:
  Nat.add(n, x)

def f(xs: List<Nat>) -> Nat:
  match xs:
    case []:
      0n
    case h <> t:
      T(~h, 1n)

def main() -> Nat:
  f([1n])

#|Error:
#|- expected : a template applied to closed ~ arguments (h is a variable here, not comptime: pass it at run time)
#|- observed : T
#|Context:
#|- h : Nat
#|- t : List<&1, Nat>
#|Location: f
#|12 |     case h <> t:
#|13>|       T(~h, 1n)
#|   |       ^
#|14 |
#|exit 1
