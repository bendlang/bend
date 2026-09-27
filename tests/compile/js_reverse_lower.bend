# String.reverse.go's loop compiles to one flat reverse on the JS lane
# (Array.from(s).reverse().join("") + acc), the same value over code
# points, with no rope node per character. The loop is gone, so what
# this pins is the value: for Base's def, for a def with the same body
# under another name, and for one whose parameters are the other way
# round -- the pass matches the shape, not a name or a position.
import Base

def rev_into(s: String, acc: String) -> String:
  match s:
    case SNil{}:
      acc
    case SCon{h, t}:
      rev_into(t, SCon{h, acc})

# rev_into with the parameters exchanged: the accumulator is the first
# one, so the pass must bind them from their use, not from their order
def rev_tail(acc: String, s: String) -> String:
  match acc:
    case SNil{}:
      s
    case SCon{h, t}:
      rev_tail(t, SCon{h, s})

def main() -> IO(Unit):
  do IO<Unit>:
    IO.print(String.reverse("abc"))
    IO.print("<" ++ String.reverse("") ++ ">")
    IO.print(Bool.show(String.eq(String.reverse("a\u{1F600}b"),
      "b\u{1F600}a")))
    IO.print(Bool.show(String.eq(String.reverse("\u{1F600}"),
      "\u{1F600}")))
    IO.print(Nat.show(String.length(String.reverse("a\u{1F600}b"))))
    IO.print(rev_into("xy", "Z"))
    IO.print(rev_into("", "Z"))
    IO.print(Bool.show(String.eq(rev_into("a\u{1F600}b", "Z"),
      "b\u{1F600}aZ")))
    IO.print(rev_tail("ab", "Z"))
    IO.print(rev_tail("", "Z"))

#|cba
#|<>
#|True
#|True
#|3
#|yxZ
#|Z
#|True
#|baZ
#|Z
