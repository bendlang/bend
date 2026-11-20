# Splitting preserves empty fields and matches whole Bend characters.
# A single long line and a file with many short lines must both fit.
import Base

def grow(n: Nat, +s: String) -> String:
  match n:
    case 0n:
      s
    case 1n+p:
      grow(p, s ++ s)

def fields(xs: List<&2, String>) -> String:
  List.show(~&2, ~String, ~(s => s), xs)

def apply(f: @+sep: Char -> List<&2, String>, sep: Char) -> List<&2, String>:
  f(sep)

def split_cons(-c: Char, -s: String, -sep: Char) ->
  {String.split(SCon{c, s}, sep) ==
   String.split.fin(c, String.split(s, sep), Char.is_eq(c, sep)) : List<&2, String>}:
  {==}

def main() -> IO(Unit):
  packed = String.split("a\u{ffffffff}b\u{1fffffff}c", '\u{ffffffff}')
  payload = String.split("a\u{110061}b", 'a')
  crlf = String.lines("a\r\n\nb\n")
  long = String.lines(grow(15n, "ab"))
  short = String.lines(grow(16n, "a\n"))
  do IO<Unit>:
    IO.print(Nat.show(List.length(&2, String, String.split("", ','))))
    IO.print(fields(apply(String.split("🙂tea🙂🙂茶🙂"), '🙂')))
    IO.print(Bool.show(String.eq(String.join(packed, "|"), "a|b\u{1fffffff}c")))
    IO.print(Bool.show(String.eq(String.join(payload, "|"), "|\u{110061}b")))
    IO.print(Bool.show(String.eq(String.join(crlf, "|"), "a\r||b|")))
    IO.print(Nat.show(String.length(String.join(long, "\n"))))
    IO.print(Nat.show(List.length(&2, String, short)))

#|1
#|[, tea, , 茶, ]
#|True
#|True
#|True
#|65536
#|65537
