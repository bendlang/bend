import Base

def down(n: Nat) -> Nat:
  match n:
    case 12n:
      down(11n)
    case _:
      n

def main() -> Nat:
  down(3n)
