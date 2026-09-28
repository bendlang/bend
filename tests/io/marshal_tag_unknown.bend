# io (io_marshal_tag_unknown): a value the host hands in converts by
# its constructor tag, so a tag its type lacks fail-stops at the seam,
# naming the tag and the type's tags; it passed through unconverted, and
# its BigInt Nat failed far off (#1105)
import Base

type Box is Data:
  Box{n: Nat}

law good:
  IO(Box)

def good():
  import "./marshal_tag_unknown.js"

law bad:
  IO(Box)

def bad():
  import "./marshal_tag_unknown.js"

def n_of(b: Box) -> Nat:
  Box{n} = b
  n

def main() -> IO(Unit):
  do IO<Unit>:
    a : Box <- good()
    u : Unit <- IO.print(Nat.show(Nat.add(n_of(a), 1n)))
    b : Box <- bad()
    IO.print(Nat.show(Nat.add(n_of(b), 1n)))

#|6
#|bend: Box has no tag Bogus (its tags: Box); a tag names its constructor as the loading file sees it, which a later version will make the same everywhere (#1105)
#|exit 1
