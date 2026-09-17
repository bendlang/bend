# a + on a pattern binder re-binds it reusable: case Circle{+r}: body
# is case Circle{r}: +r = r; body, and a variable row does the same
import Base

type Shape is Data:
  Circle{r: U32}
  Square{s: U32}

def area(x: Shape) -> U32:
  match x:
    case Circle{+r}:
      (3 * r * r : U32)
    case Square{+s}:
      (s * s : U32)

def twice(x: U32) -> U32:
  match x:
    case +y:
      (y + y : U32)

def main() -> IO(Unit):
  do IO<Unit>:
    IO.print(U32.show(area(Circle{2})))
    IO.print(U32.show(area(Square{5})))
    IO.print(U32.show(twice(4)))

#|12
#|25
#|8
