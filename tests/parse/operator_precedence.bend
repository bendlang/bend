# infix operators: bend3's ladder in bend's dialect, loosest to tightest: ||
# over && over < <= > over .|. over .^. over .&. over << >> over + - over * /;
# value ops left-assoc, <> ++ right-assoc. == != % are out: the Eql brace form
# owns ==/!= and % heads a rewrite (value equality is U32.is_eq); float twins
# ride a trailing dot, pinned by the float family. shift counts are Nat literals
# (U32.shln's own law).
import Base

law bu:
  for b: Bool
  U32

def bu(b):
  match b:
    case True{}:
      1
    case False{}:
      0

law main.out:
  U32

def main.out():
  a = (2 + 3 * 4 : U32)              # 14  (* over +)
  b = (2 + 2 << 1n : U32)            # 8   (+ over <<)
  c = (6 .&. 3 << 1n : U32)          # 6   (<< over .&.)
  d = (4 .^. 6 .&. 3 : U32)          # 6   (.&. over .^.)
  e = (1 .|. 6 .^. 4 : U32)          # 3   (.^. over .|.)
  f = bu((3 <= 1 .|. 2 : U32))       # 1   (.|. over <=)
  g = bu(True{} && False{} || True{})  # 1 (&& over ||)
  h = (10 - 2 - 3 : U32)             # 5   (left assoc)
  (a + b + c + d + e + f + g + h : U32)

law main:
  IO(Unit)

def main():
  IO.print(U32.show(main.out()))

#|44
