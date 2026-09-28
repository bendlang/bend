import Base
def discard(~f: Nat -> Nat, x: Nat) -> Nat: x
def main() -> Nat: discard(~later, 3n)
def later(n: Nat) -> Nat: Nat.mul(n, 10n)
