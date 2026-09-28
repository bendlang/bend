import Base

def down(n: Nat) -> Nat:
  match n:
    case 64n:
      down(65n)
    case _:
      n

def main() -> Nat:
  down(3n)
