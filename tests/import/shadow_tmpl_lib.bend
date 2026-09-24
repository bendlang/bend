# a module with two templates: F names Base's Nat.add and G the module's
# own pick, which its importer declares for itself too
import Base

def F(~n: Nat, x: Nat) -> Nat:
  Nat.add(n, x)

def pick(a: Nat, b: Nat) -> Nat:
  0n

def G(~n: Nat, x: Nat) -> Nat:
  pick(n, x)

#|All terms check.
