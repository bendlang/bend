# Dense hits interleave with masked defaults; high bits must not alias a hit.
import Base

def choose(+tag: U32, +salt: U32) -> U32:
  match tag:
    case 0: ((salt * 3) + 7919 : U32)
    case 1: ((salt * 5) + 15838 : U32)
    case 2: ((salt * 7) + 23757 : U32)
    case 3: ((salt * 9) + 31676 : U32)
    case 4: ((salt * 11) + 39595 : U32)
    case 5: ((salt * 13) + 47514 : U32)
    case 6: ((salt * 15) + 55433 : U32)
    case 7: ((salt * 17) + 63352 : U32)
    case 8: ((salt * 19) + 71271 : U32)
    case 9: ((salt * 21) + 79190 : U32)
    case 10: ((salt * 23) + 87109 : U32)
    case 11: ((salt * 25) + 95028 : U32)
    case 12: ((salt * 27) + 102947 : U32)
    case 13: ((salt * 29) + 110866 : U32)
    case 14: ((salt * 31) + 118785 : U32)
    case 15: ((salt * 33) + 126704 : U32)
    case U32{WCon{False{}, _}}: U32.xor(salt, 305419896)
    case _: U32.xor(salt, 3735928559)

def sum(n: Nat, +i: U32, acc: U32) -> U32:
  match n:
    case 0n: acc
    case 1n+p:
      sum(p, (i + 1 : U32), U32.xor(acc, choose(i, (i * 2654435761 : U32))))

def main() -> IO(Unit):
  do IO<Unit>:
    IO.print(U32.show(sum(257n, 0, 0)))
    IO.print(U32.show(sum(33n, 4294967280, 0)))

#|466958072
#|290700264
