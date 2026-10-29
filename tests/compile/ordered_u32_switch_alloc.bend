# Dense word dispatch retains one common allocation and consumes each list once.
import Base

def choose(+tag: U32, +salt: U32) -> List<U32>:
  match tag:
    case 0: (salt + 0 : U32) <> Nil{}
    case 1: (salt + 1 : U32) <> Nil{}
    case 2: (salt + 2 : U32) <> Nil{}
    case 3: (salt + 3 : U32) <> Nil{}
    case 4: (salt + 4 : U32) <> Nil{}
    case 5: (salt + 5 : U32) <> Nil{}
    case 6: (salt + 6 : U32) <> Nil{}
    case 7: (salt + 7 : U32) <> Nil{}
    case 8: (salt + 8 : U32) <> Nil{}
    case 9: (salt + 9 : U32) <> Nil{}
    case 10: (salt + 10 : U32) <> Nil{}
    case 11: (salt + 11 : U32) <> Nil{}
    case 12: (salt + 12 : U32) <> Nil{}
    case 13: (salt + 13 : U32) <> Nil{}
    case 14: (salt + 14 : U32) <> Nil{}
    case 15: (salt + 15 : U32) <> Nil{}
    case U32{WCon{False{}, _}}: U32.xor(salt, 305419896) <> Nil{}
    case _: U32.xor(salt, 3735928559) <> Nil{}

def read(xs: List<U32>) -> U32:
  match xs:
    case Nil{}: 0
    case Con{x, _}: x

def sum(n: Nat, +i: U32, acc: U32) -> U32:
  match n:
    case 0n: acc
    case 1n+p:
      sum(p, (i + 1 : U32), U32.xor(acc, read(choose(i, (i * 2654435761 : U32)))))

def main() -> IO(Unit):
  IO.print(U32.show(sum(257n, 0, 0)))

#|414374136
