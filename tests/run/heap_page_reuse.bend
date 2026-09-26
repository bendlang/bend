# Build and discard interleaved number strings across several parallel rounds.
# More than one generation of one-word cells is returned to the shared bank.
import Base

def cell(+x: U32, +y: U32) -> String:
  U32.show(x) ++ " " ++ U32.show(y) ++ "\n"

def row(n: Nat, +x: U32, +y: U32) -> String:
  match n:
    case 0n:
      ""
    case 1n+p:
      cell(x, y) ++ row(p, (x + 1 : U32), y)

def rows(+d: Nat, +y: U32) -> String:
  match d:
    case 0n:
      row(128n, 0, y)
    case 1n+p:
      +half = (1 << p : U32)
      a b = rows(p, y) rows(p, (y + half : U32))
      a ++ b

def loop(n: Nat, +y: U32) -> IO(Unit):
  match n:
    case 0n:
      IO.pure(Unit, Unit{})
    case 1n+p:
      do IO<Unit>:
        IO.print(Nat.show(String.length(rows(5n, y))))
        loop(p, (y + 45 : U32))

def main() -> IO(Unit):
  loop(4n, 0)

#|23872
#|25152
#|27968
#|29248
