# a float comparison chain (: F32) at the comparison level: < ranks
# below + (F32.is_lt is the one comparison the C emitter carries; the
# rest are pinned yellow by run_float_specials)
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
  a = bu((0.5 < 1.5 : F32))                      # 1
  b = bu((2.5 < 0.5 + 1.0 : F32))              # 0 (+ first: 2.5 < 1.5)
  (a * 10 + b : U32)

law main:
  IO(Unit)

def main():
  IO.print(U32.show(main.out()))

#|10
