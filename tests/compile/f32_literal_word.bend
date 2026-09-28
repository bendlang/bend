# a float literal is one Lit node; the compiler reads it as its word,
# so a float immediate, float arithmetic and a match on float literal
# patterns reach all three lanes as the number they are
import Base

def key(x: F32) -> U32:
  match x:
    case 1.5:
      10
    case 2.5:
      20
    case _:
      30

def main() -> IO(Unit):
  IO.print(F32.show(F32.add(1.5, 2.5)) ++ " " ++ U32.show(key(1.5)))

#|4 10
