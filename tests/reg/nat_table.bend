# a match on a Nat whose arms are constants, or macro-only intrinsics over
# constants, is one table: TAB_AT over a CONSTV array of literals in C (the rows
# evaluated at compile time) and an indexed array in JS, with or without a
# default arm; the emit-style lane pins the width.
import Base

def flag(c: Nat) -> U32:
  match c:
    case 99n:
      1
    case 120n:
      2
    case 116n:
      3
    case 122n:
      (2 * 2 : U32)
    case k:
      5

def main() -> IO(Unit):
  IO.print(U32.show((flag(U32.to_nat(116)) * 100 + flag(U32.to_nat(7)) : U32)))

#|305
