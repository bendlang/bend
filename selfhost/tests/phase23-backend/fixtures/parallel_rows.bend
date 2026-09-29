import Base

@unsafe
def total(+depth: Nat, +x: U32) -> U32:
  match depth:
    case 0n:
      x
    case 1n+p:
      a b = total(p, (x + 1 : U32)) total(p, (x + 2 : U32))
      (a + b : U32)

def main() -> U32:
  total!(10n, 1)

#|16384
