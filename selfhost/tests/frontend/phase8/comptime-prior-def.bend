import Base
def app(~f: Nat -> Nat, x: Nat) -> Nat: f(x)
def earlier(n: Nat) -> Nat: Nat.mul(n, 10n)
def main() -> Nat: app(~earlier, 3n)
