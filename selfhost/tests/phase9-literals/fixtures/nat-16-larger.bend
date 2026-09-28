import Base

def down(n: Nat) -> Nat:
  match n:
    case 16n:
      down(17n)
    case _:
      n

def main() -> Nat:
  down(3n)
