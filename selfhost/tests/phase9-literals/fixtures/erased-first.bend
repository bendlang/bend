import Base

def down(-ignored: Nat, n: Nat) -> Nat:
  match n:
    case 8n:
      down(99n, 7n)
    case _:
      n

def main() -> Nat:
  down(0n, 8n)
