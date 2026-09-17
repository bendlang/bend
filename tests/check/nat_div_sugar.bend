# `/` and `%` name T.div and T.mod, and T defaults to Nat: Nat.div and
# Nat.mod read the quotient and the remainder off Nat.divmod
import Base

def main() -> Nat & Nat:
  ((7n / 2n : Nat), (7n % 2n : Nat))

#|(3n, 1n)
