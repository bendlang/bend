import Base

def a.b(n: Nat) -> Nat:
  match n:
    case 0n: 0n
    case 1n+p: Succ{a.b(p)}
def a_b(n: Nat) -> Nat:
  match n:
    case 0n: 1n
    case 1n+p: Succ{a_b(p)}
def inspect() -> IO(U32):
  import "./foreign_fid.c"
  import "./foreign_fid.js"
def main() -> IO(Unit):
  do IO<Unit>:
    n : U32 <- inspect()
    IO.print(Nat.show(a_b(a.b(U32.to_nat(n)))))

#|2
