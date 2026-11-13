import Base

# String.cmp answers both of its strings unchanged, so the C lane runs its
# core, a borrowed walk that builds nothing, and each call takes its own
# strings back. Every call here must answer as the def does: the order,
# and both strings intact after it.

def code(c: Cmp) -> String:
  match c:
    case LT{}:
      "<"
    case EQ{}:
      "="
    case GT{}:
      ">"

def show(r: (String & String) & Cmp) -> String:
  ((a, b), c) = r
  code(c) ++ "[" ++ a ++ "|" ++ b ++ "]"

# the strings that come back are walked again
def again(r: (String & String) & Cmp) -> String:
  ((a, b), c) = r
  code(c) ++ show(String.cmp(b, a))

def chain(n: Nat, r: (String & String) & Cmp, acc: U32) -> String:
  match n:
    case 0n:
      ((a, b), c) = r
      U32.show(acc) ++ code(c) ++ a ++ b
    case 1n+p:
      ((a, b), c) = r
      chain(p, String.cmp(b, a), U32.add(acc, Bool.to_u32(Cmp.is_lt(c))))

def shared(+s: String, +t: String) -> String:
  show(String.cmp(s, t)) ++ show(String.cmp(t, s)) ++ s ++ t

def main() -> IO(Unit):
  do IO<Unit>:
    IO.print(show(String.cmp("", "")))
    IO.print(show(String.cmp("", "a")))
    IO.print(show(String.cmp("a", "")))
    IO.print(show(String.cmp("ab", "abc")))
    IO.print(show(String.cmp("abd", "abc")))
    IO.print(show(String.cmp("same", "same")))
    IO.print(show(String.cmp(String.append("ab", "c"), String.repeat("b", 2n))))
    IO.print(again(String.cmp("xy", "xz")))
    IO.print(chain(5n, String.cmp("ba", "bb"), 0))
    IO.print(shared("hello", "help"))
    IO.print(code(Pair.snd(String & String, Cmp,
      String.cmp("\u{ffffffff}", "\u{7fffffff}"))))
    IO.print(code(Pair.snd(String & String, Cmp,
      String.cmp(String.repeat("q", 300n), String.append(String.repeat("q", 299n), "r")))))

#|=[|]
#|<[|a]
#|>[a|]
#|<[ab|abc]
#|>[abd|abc]
#|=[same|same]
#|<[abc|bb]
#|<>[xz|xy]
#|3>bbba
#|<[hello|help]>[help|hello]hellohelp
#|>
#|<
