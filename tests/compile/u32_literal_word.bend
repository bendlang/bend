# a u32 literal is one Lit node; the compiler reads it as its word, so a
# wide immediate, a wrapping operation and a match on wide literal
# patterns reach all three lanes as the number they are
import Base

def key(n: U32) -> U32:
  match n:
    case 0:
      10
    case 3000000000:
      20
    case 4294967295:
      30
    case _:
      40

def word() -> U32:
  U32.add(4294967290, 10)

def main() -> IO(Unit):
  a = key(3000000000)
  b = key(4294967295)
  c = key(7)
  d = word()
  IO.print(U32.show(U32.add(a, U32.add(b, U32.add(c, d)))) ++ " " ++ Char.show('q'))

#|94 q
