import Base
def app?(~f: Nat -> Nat, x: Nat) -> Nat: f(x)
def main() -> Nat: app(~later, 3n)
def later(n: Nat) -> Nat: Nat.mul(n, 10n)
