# String.eq on JS is ===: a String's text is canonical, including codes
# outside Unicode scalars (char_new's marker form), so equal Strings
# (built, sliced or literal) are equal texts, and unequal ones are not.
import Base

def one(x: U32) -> String:
  SCon{Char.from_u32(x), SNil{}}

def two(x: U32, y: U32) -> String:
  String.append(one(x), one(y))

def self_codes(xs: List<&2, U32>) -> Bool:
  match xs:
    case Nil{}:
      True{}
    case +x <> t:
      Bool.and(String.eq(one(x), one(x)), self_codes(t))

def tail(s: String) -> String:
  match s:
    case SNil{}:
      SNil{}
    case SCon{_, t}:
      t

def apply(f: @p: String -> Bool, p: String) -> Bool:
  f(p)

def main() -> IO(Unit):
  do IO<Unit>:
    IO.print(Bool.show(String.eq("", "")))
    IO.print(Bool.show(String.eq("", "a")))
    IO.print(Bool.show(String.eq("abc", "abc")))
    IO.print(Bool.show(String.eq("abc", "abd")))
    IO.print(Bool.show(String.eq("abc", "ab")))
    IO.print(Bool.show(String.eq("ab", "abc")))
    IO.print(Bool.show(String.eq(String.append("settings_", "proposal"), "settings_proposal")))
    IO.print(Bool.show(String.eq(tail("xsettings"), "settings")))
    IO.print(Bool.show(String.eq("a😀b", "a😀b")))
    IO.print(Bool.show(String.eq("a😀b", "a😁b")))
    IO.print(Bool.show(String.eq(two(55357, 56832), "😀")))
    IO.print(Bool.show(String.eq(one(128512), "😀")))
    IO.print(Bool.show(String.eq(one(55296), one(55296))))
    IO.print(Bool.show(String.eq(one(55296), one(56320))))
    IO.print(Bool.show(String.eq(one(4294967295), one(4294967294))))
    IO.print(Bool.show(String.eq(one(1114112), one(1114112))))
    IO.print(Bool.show(String.eq(two(56320, 0), one(56320))))
    IO.print(Bool.show(apply(String.eq("q"), "q")))
    IO.print(Bool.show(self_codes([0, 65, 55295, 55296, 56320, 57343, 57344,
      65536, 1114111, 1114112, 1114209, 4194304, 2147483648, 4294967295])))

#|True
#|False
#|True
#|False
#|False
#|False
#|True
#|True
#|True
#|False
#|False
#|True
#|True
#|False
#|False
#|True
#|False
#|True
#|True
