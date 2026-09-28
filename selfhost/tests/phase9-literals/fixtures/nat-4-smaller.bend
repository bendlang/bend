import Base

def down(n: Nat) -> Nat:
  match n:
    case 4n:
      down(3n)
    case _:
      n

def main() -> Nat:
  down(3n)
