# Constructor/match, polymorphic Data containers and partial application.
import Base

def pass(~A: Data, x: A) -> A:
  x

def tail(s: String) -> String:
  match s:
    case SNil{}:
      ""
    case SCon{h, t}:
      t

def both(+s: String) -> String & String:
  (tail(s), s)

def apply(f: String -> String, s: String) -> String:
  f(s)

def array_finish(ax: Array<String> & String, by: Array<String> & String) -> String:
  (a, x) = ax
  (b, y) = by
  String.append(String.to_upper(x), y)

def array_cloned(ab: Array<String> & Array<String>) -> String:
  (a, b) = ab
  array_finish(Array.get(String, a, 1), Array.get(String, b, 2))

def array_roundtrip(s: String) -> String:
  array_cloned(Array.clone(String, Array.new(String, 2n, s)))

def main() -> (String & String) & (List<&2, String> & (String & String)):
  +s = pass(~String, SCon{'a', SCon{'😀', SCon{'z', SNil{}}}})
  (both(s), ([pass(~String, tail(s)), s, apply(String.reverse, s),
    array_roundtrip(String.copy(s))],
    (apply(t => SCon{'!', t}, s), apply(String.append("x"), s))))

#|(("😀z", "a😀z"), ["😀z", "a😀z", "z😀a", "A😀Za😀z"], "!a😀z", "xa😀z")
