# a literal pattern past 256 whose default arm uses the scrutinee rebuilds
# it as one checked sum, nat_chk(e, x + 300), not a check per Succ: 300
# nested calls topped clang's bracket nesting and the C lane failed
import Base

def down(n: Nat) -> Nat:
  match n:
    case 300n:
      down(299n)
    case _:
      n

def main() -> Nat:
  Nat.add(down(300n), down(7n))

#|306n
