# A match on a String takes one Char at a time whatever its width on the
# JS lane, where an astral code point is a surrogate pair and a code that
# is no scalar is packed in four units: each comes off as one Char with
# its own code, and the rest walks on.
import Base

def one(n: U32) -> String:
  SCon{Char.from_u32(n), SNil{}}

def text() -> String:
  String.append("a🙂é", String.append(one(4294967295),
    String.append(one(56320), String.append(one(55296), "z"))))

def walk(s: String, n: U32, acc: U32) -> Pair(U32, U32):
  match s:
    case SNil{}:
      (n, acc)
    case SCon{Chr{c}, t}:
      walk(t, (n + 1 : U32), (acc * 31 + c : U32))

law main:
  Pair(U32, U32)

def main():
  walk(text(), 0, 0)

#|(7, 751504163)
