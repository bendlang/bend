# String.contains searches without taking either string apart: a text or a
# pattern the caller keeps, shares, built for the call or handed over in a
# tail call gives the same answer, and what the caller keeps reads the same
# afterwards. The texts are built at run time, so they sit on the heap.
import Base

def one(x: U32) -> String:
  SCon{Char.from_u32(x), SNil{}}

# Another caller hands String.starts_with a built string in a tail call.
def starts_built(a: String, b: String) -> Bool:
  String.starts_with(String.append(a, b), "ab")

# A kept text and a kept pattern, each read whole after two searches.
def kept(+s: String, +p: String) -> String:
  Bool.show(String.contains(s, p)) ++ Bool.show(String.contains(s, p))
    ++ " " ++ Nat.show(String.length(s)) ++ " " ++ String.take(s, 5n)
    ++ " " ++ Nat.show(String.length(p)) ++ " " ++ String.take(p, 3n)

# A tail of a kept text shares its cells with it.
def tails(+s: String, +p: String) -> String:
  +t = String.drop(s, 4n)
  Bool.show(String.contains(t, p)) ++ Bool.show(String.contains(s, p))
    ++ Bool.show(String.contains(t, s)) ++ Bool.show(String.contains(s, t))
    ++ " " ++ String.take(t, 6n) ++ " " ++ Nat.show(String.length(t))
    ++ " " ++ Nat.show(String.length(s))

# A text built for the search, and a search that is the def's tail call.
def owned(a: String, b: String, p: String) -> Bool:
  String.contains(String.append(a, b), p)

# The words of a kept list, each searched in place.
def count(ws: List<&2, String>, +p: String, acc: Nat) -> Nat:
  match ws:
    case Nil{}:
      acc
    case +w <> t:
      count(t, p, Nat.add(Nat.add(acc, String.length(w)),
        Bool.pick(Nat, String.contains(w, p), 100n, 0n)))

def words(+n: Nat) -> List<&2, String>:
  [String.repeat("ab", n), String.repeat("b", n), "", String.repeat("ba", Nat.add(n, n))]

def show(b: Bool) -> String:
  Bool.pick(String, b, "1", "0")

def main() -> IO(Unit):
  do IO<Unit>:
    xs : List<String> <- IO.args()
    +n : Nat = List.length(&1, String, xs)
    +ab : String = String.repeat("ab", Nat.add(n, 2n))
    +big : String = String.repeat("abc", Nat.add(n, 299n))
    +hi : String = String.append(one(1114209), String.append(one(128512), String.repeat("x", n)))
    +ws : List<&2, String> = words(Nat.add(n, 1n))
    IO.print(kept(ab, "ba"))
    IO.print(kept(ab, "bb"))
    IO.print(kept(ab, String.repeat("ab", Nat.add(n, 2n))))
    IO.print(kept(ab, String.repeat("ab", Nat.add(n, 3n))))
    IO.print(kept(ab, String.repeat("b", n)))
    IO.print(kept(ab, String.repeat("b", Nat.sub(n, 1n))))
    IO.print(kept(String.repeat("b", Nat.sub(n, 1n)), String.repeat("b", Nat.sub(n, 1n))))
    IO.print(kept(String.repeat("b", Nat.sub(n, 1n)), ab))
    IO.print(kept(String.append(big, "d"), "cd"))
    IO.print(kept(String.append(big, "d"), "cabd"))
    IO.print(kept(String.repeat("a", Nat.add(n, 5n)), "aaab"))
    IO.print(kept(String.append(String.repeat("a", Nat.add(n, 5n)), "b"), "aaab"))
    IO.print(kept(hi, one(128512)))
    IO.print(kept(hi, String.append(one(128512), "x")))
    IO.print(kept(hi, one(55357)))
    IO.print(kept(hi, String.append(one(1114209), one(128513))))
    IO.print(tails(ab, "abab"))
    IO.print(tails(String.append(big, "d"), "abcd"))
    IO.print(show(owned(ab, big, "babc")) ++ show(owned(ab, big, "bb"))
      ++ show(owned(ab, "", "")) ++ show(owned("", "", ab))
      ++ show(starts_built(ab, big)) ++ show(starts_built("", hi))
      ++ show(String.contains(ab, ab)) ++ show(String.contains(ab, big))
      ++ show(String.contains(big, ab)) ++ show(String.contains(big, String.drop(big, 890n))))
    IO.print(Nat.show(count(ws, "ba", 0n)) ++ " " ++ Nat.show(count(ws, "", 0n))
      ++ " " ++ Nat.show(count(ws, ab, 0n)) ++ " " ++ String.join(ws, ","))
    IO.print(ab ++ " " ++ String.drop(hi, 1n) ++ " " ++ Nat.show(String.length(big)))

#|TrueTrue 6 ababa 2 ba
#|FalseFalse 6 ababa 2 bb
#|TrueTrue 6 ababa 6 aba
#|FalseFalse 6 ababa 8 aba
#|TrueTrue 6 ababa 1 b
#|TrueTrue 6 ababa 0 
#|TrueTrue 0  0 
#|FalseFalse 0  6 aba
#|TrueTrue 901 abcab 2 cd
#|FalseFalse 901 abcab 4 cab
#|FalseFalse 6 aaaaa 4 aaa
#|TrueTrue 7 aaaaa 4 aaa
#|TrueTrue 3 �😀x 1 😀
#|TrueTrue 3 �😀x 2 😀x
#|FalseFalse 3 �😀x 1 �
#|FalseFalse 3 �😀x 2 �😁
#|FalseTrueFalseTrue ab 2 6
#|TrueTrueFalseTrue bcabca 897 901
#|1010101001
#|214 414 114 abab,bb,,babababa
#|ababab 😀x 900
