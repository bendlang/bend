# cons operator h<>t, in terms and patterns -- ported from bend3.
# dialect divergence: bend's String is its own SCon/SNil type, not
# List<&2, Char>, so <> builds List's Con only; lc respells a String as
# List<&2, Char> with both sugars, and the '/'-pair test rides Char.eq
# over cons PATTERNS (a char-literal pattern is a 32-ctor word tree,
# not a pattern; Char.eq rides U32.cmp, the reg_word_copy_native
# tocl seam, so the codes compare as U32 -- '/' is 47)
import Base

law lc:
  for s: String
  List<&2, Char>

def lc(s):
  match s:
    case SCon{h, t}:
      h <> lc(t)
    case SNil{}:
      []

law len:
  for s: List<&2, Char>
  U32

def len(s):
  match s:
    case h <> t:
      (1 + len(t) : U32)
    case Nil{}:
      0

law slashes.bit:
  for b: Bool
  U32

def slashes.bit(b):
  match b:
    case True{}:
      1
    case False{}:
      0

law slashes:
  for s: List<&2, Char>
  U32

def slashes(s):
  match s:
    case Chr{a} <> Chr{b} <> t:
      slashes.bit(U32.is_eq(a, 47) && U32.is_eq(b, 47))
    case t:
      0

law main.out:
  U32

def main.out():
  (len('a' <> lc("bc")) * 100 + 65 + (122 - 97) + slashes(lc("//x")) + slashes(lc("/x")) * 10 : U32)

law main:
  IO(Unit)

def main():
  IO.print(U32.show(main.out()))

#|391
