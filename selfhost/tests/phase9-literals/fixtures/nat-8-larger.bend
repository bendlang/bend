import Base

def down(n: Nat) -> Nat:
  match n:
    case 8n:
      down(9n)
    case _:
      n

def main() -> Nat:
  down(3n)
