# Code-point windows, wide Nat bounds, reversed and nested views.
import Base

def big() -> Nat:
  Nat.pow(2n, 32n)

def cut_show(ab: String & String) -> String:
  (a, b) = ab
  String.append(a, String.append("|", b))

def main() -> (List<&2, Maybe<&2, Char>> & List<&2, String>) & (String & String):
  +s = {"A😀éZ" : String}
  (([String.get(s, 0n), String.get(s, 1n), String.get(s, 4n),
     String.get(s, big()), String.get_end(s, 1n), String.get_end(s, 4n),
     String.get_end(s, 0n), String.get_end(s, big())],
    [String.take(s, 2n), String.drop(s, 2n), String.take(s, big()),
     String.drop(s, big()), String.slice(s, 1n, 3n),
     String.slice(s, 3n, 1n), String.slice(s, big(), big()),
     String.slice(s, 2n, big()), String.take_end(s, 2n),
     String.drop_end(s, 2n), String.take_end(s, big()),
     String.drop_end(s, big()), String.take_end(s, 0n), String.drop_end(s, 0n),
     String.slice(String.reverse(s), 1n, 3n),
     String.slice(String.slice(s, 1n, 4n), 1n, 2n),
     String.take("", big()), String.drop("", big()),
     String.take(s, 0n), String.drop(s, 0n), String.slice(s, 0n, 0n),
     cut_show(String.cut(s, 0n)), cut_show(String.cut(s, big()))]),
   String.cut(s, 2n))

#|(([Some{'A'}, Some{'😀'}, None{}, None{}, Some{'Z'}, Some{'A'}, None{}, None{}], ["A😀", "éZ", "A😀éZ", "", "😀é", "", "", "éZ", "éZ", "A😀", "A😀éZ", "", "", "A😀éZ", "é😀", "é", "", "", "", "A😀éZ", "", "|A😀éZ", "A😀éZ|"]), "A😀", "éZ")
