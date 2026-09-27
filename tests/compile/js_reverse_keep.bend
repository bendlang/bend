# A def that only looks like String.reverse.go must keep its loop: an
# endless block over a String, the same SNil/SCon match and the same
# code-point advance are not enough -- what the accumulator gets is.
# The lowering is a replacement of the whole loop, so a pass that
# matched the skeleton would answer wrongly here and nowhere else.
import Base

# the accumulator holds a "!" between the head and the rest, so the
# answer is "b!a!" where a flat reverse would say "ba"
def bang.go(s: String, acc: String) -> String:
  match s:
    case SNil{}:
      acc
    case SCon{h, t}:
      bang.go(t, SCon{h, SCon{'!', acc}})

# three parameters, and the accumulator is the third: a pass that took
# the second parameter for it would reverse into the Nat
def tri.go(s: String, n: Nat, acc: String) -> String:
  match s:
    case SNil{}:
      acc
    case SCon{h, t}:
      tri.go(t, n, SCon{h, acc})

def main() -> IO(Unit):
  do IO<Unit>:
    IO.print(bang.go("ab", ""))
    IO.print(bang.go("ab", "Z"))
    IO.print(tri.go("ab", 7n, ""))
    IO.print(tri.go("", 7n, "Z"))

#|b!a!
#|b!a!Z
#|ba
#|Z
