import Base

def down(n: Nat) -> Nat:
  match n:
    case 128n:
      down(127n)
    case _:
      n

def main() -> Nat:
  down(3n)
