import Base

# String.cmp, Map.has and Map.get answer their arguments unchanged, and so
# do the defs below (tag inside either of its constructors, swap crossed,
# first beside a copy of a part), so the C lane runs their cores (borrowed
# walks that build nothing) and each call takes its own arguments back.
# Every call here must answer as the def does, with its arguments intact.

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

type Tree is Data:
  Leaf{}
  Node{l: Tree, v: U32, r: Tree}

def Tree.sum.k(+v: U32, lr: Tree & U32, rr: Tree & U32) -> Tree & U32:
  (l, a) = lr
  (r, b) = rr
  (Node{l, v, r}, U32.add(U32.add(a, b), v))

def Tree.sum(t: Tree) -> Tree & U32:
  match t:
    case Leaf{}:
      (Leaf{}, 0)
    case Node{l, +v, r}:
      Tree.sum.k(v, Tree.sum(l), Tree.sum(r))

def swap(a: String, b: String) -> String & String:
  (b, a)

def first(l: List<&2, String>) -> List<&2, String> & String:
  match l:
    case []:
      ([], "")
    case +h <> t:
      (h <> t, h)

def sum.again(n: U32, r: Tree & U32) -> String:
  (t, m) = r
  U32.show(n) ++ U32.show(m)

# the tree Tree.sum answers is summed again
def sum.show(r: Tree & U32) -> String:
  (t, n) = r
  sum.again(n, Tree.sum(t))

def swap.show(r: String & String) -> String:
  (a, b) = r
  a ++ b

def first.again(h: String, r: List<&2, String> & String) -> String:
  (l, h2) = r
  h ++ h2

# the list first answers is read again
def first.show(r: List<&2, String> & String) -> String:
  (l, h) = r
  first.again(h, first(l))

def main() -> IO(Unit):
  do IO<Unit>:
    IO.print(sum.show(Tree.sum(Node{Node{Leaf{}, 1, Leaf{}}, 5, Node{Leaf{}, 9, Leaf{}}})))
    IO.print(swap.show(swap("ab", "cd")))
    IO.print(first.show(first(["x", "y"])) ++ first.show(first([])))
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

#|1515
#|cdab
#|xx
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
