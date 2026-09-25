# a ~ argument is a closed term: it checks in the empty context, so a
# let-bound name, a variable of the caller's context like a parameter, is
# unbound there and the call is refused (see err_leak)
import Base

def app(~f: Nat -> Nat, x: Nat) -> Nat:
  f(x)

def main() -> Nat:
  g = {y => Nat.add(y, 10n) : Nat -> Nat}
  app(~g, 1n)

#|Error:
#|- expected : a template applied to closed ~ arguments (g is a variable here, not comptime: pass it at run time)
#|- observed : app
#|Context:
#|- g : @_:Nat -> Nat
#|Location: main
#|10 |   g = {y => Nat.add(y, 10n) : Nat -> Nat}
#|11>|   app(~g, 1n)
#|   |   ^^^
#|12 |
#|exit 1
