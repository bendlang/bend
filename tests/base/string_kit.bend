# the String and Char kit: length, reverse, order, prefix and suffix
# tests, contains, take/drop/get, list round trips, concat/join/split/
# lines, repeat, case mapping, trim, and the Char classes
import Base

def strs(xs: List<&2, String>) -> String:
  List.show(~&2, ~String, ~(s => s), xs)

def mc(m: Maybe<&2, Char>) -> String:
  Maybe.show(~&2, ~Char, ~(c => Char.show(c)), m)

def main() -> IO(Unit):
  do IO<Unit>:
    IO.print(Nat.show(String.length("hello")))
    IO.print(Bool.show(String.is_empty("")))
    IO.print(String.reverse("abc"))
    IO.print(Bool.show(String.is_lt("apple", "banana")))
    IO.print(Bool.show(String.is_ge("b", "apple")))
    IO.print(Bool.show(String.starts_with("hello", "he")))
    IO.print(Bool.show(String.starts_with("hello", "lo")))
    IO.print(Bool.show(String.ends_with("hello", "lo")))
    IO.print(Bool.show(String.contains("hello world", "o w")))
    IO.print(Bool.show(String.contains("hello", "xyz")))
    IO.print(Bool.show(String.contains("", "")))
    IO.print(String.take("hello", 2n))
    IO.print(String.drop("hello", 2n))
    IO.print(mc(String.get("hello", 1n)))
    IO.print(mc(String.get("hi", 5n)))
    IO.print(String.from_list(List.reverse(&2, Char, String.to_list("abc"))))
    IO.print(String.concat(["a", "b", "c"]))
    IO.print(String.join(["a", "b", "c"], ", "))
    IO.print("<" ++ String.join([], ", ") ++ ">")
    IO.print(strs(String.split("a,b,,c", ',')))
    IO.print(strs(String.lines("x\ny")))
    IO.print(String.repeat("ab", 3n))
    IO.print(String.to_upper("Hello 1"))
    IO.print(String.to_lower("Hello 1"))
    IO.print("<" ++ String.trim("  hi  ") ++ ">")
    IO.print("<" ++ String.trim_start("  hi") ++ ">")
    IO.print("<" ++ String.trim_end("hi \n") ++ ">")
    IO.print(Bool.show(Char.is_digit('7')))
    IO.print(Bool.show(Char.is_alpha('7')))
    IO.print(Bool.show(Char.is_upper('Q')))
    IO.print(Bool.show(Char.is_lower('Q')))
    IO.print(Bool.show(Char.is_space(' ')))
    IO.print(Char.show(Char.to_upper('a')) ++ Char.show(Char.to_lower('B')))
    IO.print(U32.show(Char.to_u32('A')))
    IO.print(Char.show(Char.from_u32(66)))
    IO.print(Bool.show(Char.is_eq('a', 'a')))

#|5
#|True
#|cba
#|True
#|True
#|True
#|False
#|True
#|True
#|False
#|True
#|he
#|llo
#|Some(e)
#|None
#|cba
#|abc
#|a, b, c
#|<>
#|[a, b, , c]
#|[x, y]
#|ababab
#|HELLO 1
#|hello 1
#|<hi>
#|<hi>
#|<hi>
#|True
#|False
#|True
#|False
#|True
#|Ab
#|65
#|B
#|True
