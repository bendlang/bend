import Base

def down(s: String) -> Nat:
  match s:
    case "ab":
      down("ab")
    case _:
      0n

def main() -> Nat:
  down("ab")
