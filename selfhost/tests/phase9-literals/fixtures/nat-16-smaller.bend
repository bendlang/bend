import Base

def down(n: Nat) -> Nat:
  match n:
    case 16n:
      down(15n)
    case _:
      n

def main() -> Nat:
  down(3n)
