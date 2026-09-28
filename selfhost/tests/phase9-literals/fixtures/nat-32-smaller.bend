import Base

def down(n: Nat) -> Nat:
  match n:
    case 32n:
      down(31n)
    case _:
      n

def main() -> Nat:
  down(3n)
