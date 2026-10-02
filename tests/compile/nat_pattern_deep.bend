# a literal pattern past 256 whose default arm uses the scrutinee rebuilds
# it as one checked sum, nat_chk(e, x + 300), not a check per Succ: 300
# nested calls topped clang's bracket nesting and the C lane failed. The
# 300 comes from U32.to_nat, which no build folds, so down runs its match
import Base

def down(n: Nat) -> Nat:
  match n:
    case 300n:
      down(299n)
    case _:
      n

def main() -> Nat:
  Nat.add(down(U32.to_nat(300)), down(7n))

#|306n
