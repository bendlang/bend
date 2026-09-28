import Base

def down(s: String) -> Nat:
  match s:
    case "ab":
      down("abc")
    case _:
      0n

def main() -> Nat:
  down("ab")
