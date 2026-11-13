import Base

# String.cmp and Map.has answer their arguments unchanged, and so does
# tag, inside either of its constructors, so the C lane runs their cores
# (borrowed walks that build nothing) and each call takes its own
# arguments back. Every call here must answer as the def does, with its
# arguments intact after it.

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

type Tag is Data:
  Long{s: String, n: U32}
  Short{s: String}

def tag(s: String, n: U32) -> Tag:
  match s:
    case SNil{}:
      Short{SNil{}}
    case SCon{h, t}:
      Long{SCon{h, t}, n}

def tag.show(t: Tag) -> String:
  match t:
    case Long{s, n}:
      "L" ++ s ++ U32.show(n)
    case Short{s}:
      "S" ++ s

def has.fin(b: Bool, v: U32, r: Map<&2, U32> & Bool) -> String:
  (m, n) = r
  U32.show(Bool.to_u32(b)) ++ U32.show(v) ++ U32.show(Bool.to_u32(n))

def has.get(b: Bool, r: Map<&2, U32> & U32) -> String:
  (m, v) = r
  has.fin(b, v, Map.has(&2, U32, m, "zz"))

# the map Map.has answers is read again
def has(r: Map<&2, U32> & Bool, k: String) -> String:
  (m, b) = r
  has.get(b, Map.get(U32, 0, m, k))

def keys() -> Map<&2, U32>:
  Map.set(&2, U32, Map.set(&2, U32, Map.set(&2, U32, Map.new(&2, U32),
    "abc", 1), "abd", 2), "b", 3)

def main() -> IO(Unit):
  do IO<Unit>:
    IO.print(tag.show(tag("hey", 7)) ++ tag.show(tag("", 7)))
    IO.print(has(Map.has(&2, U32, keys(), "abd"), "abd"))
    IO.print(has(Map.has(&2, U32, keys(), "ab"), "b"))
    IO.print(has(Map.has(&2, U32, Map.new(&2, U32), "a"), "a"))
    IO.print(has(Map.has(&2, U32, Map.set(&2, U32, Map.new(&2, U32), "a", 9), "a"), "a"))
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

#|Lhey7S
#|120
#|030
#|000
#|190
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
