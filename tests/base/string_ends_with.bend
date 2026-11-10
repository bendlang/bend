# A suffix is the last length(p) characters: an empty one needs nothing
# about the haystack, and a longer one never matches.
import Base

def empty_suffix(-s: String) ->
  {String.ends_with(s, "") == True{} : Bool}:
  {==}

def main() -> IO(Unit):
  do IO<Unit>:
    IO.print(Bool.show(String.ends_with("", "")))
    IO.print(Bool.show(String.ends_with("abc", "")))
    IO.print(Bool.show(String.ends_with("", "a")))
    IO.print(Bool.show(String.ends_with("abc", "c")))
    IO.print(Bool.show(String.ends_with("abc", "abc")))
    IO.print(Bool.show(String.ends_with("abc", "zabc")))
    IO.print(Bool.show(String.ends_with("abc", "b")))
    IO.print(Bool.show(String.ends_with("abc", "ac")))
    IO.print(Bool.show(String.ends_with("abc😀", "c😀")))
    IO.print(Bool.show(String.ends_with("abc😀", "😁")))
    IO.print(Bool.show(String.ends_with("a\u{ffffffff}", "\u{ffffffff}")))
    IO.print(Bool.show(String.ends_with("a\u{ffffffff}", "\u{7fffffff}")))

#|True
#|True
#|False
#|True
#|True
#|False
#|False
#|False
#|True
#|False
#|True
#|False
