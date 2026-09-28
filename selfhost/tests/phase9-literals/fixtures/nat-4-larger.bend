import Base

def down(n: Nat) -> Nat:
  match n:
    case 4n:
      down(5n)
    case _:
      n

def main() -> Nat:
  down(3n)
