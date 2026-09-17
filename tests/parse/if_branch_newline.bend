# bend blocks are layout-free: branches split across lines however
# they like (bend3 pinned a newline law; no counterpart wall exists.
# the if sugar is gone: a Bool branch is a match in its own def)
import Base

law f:
  for b: Bool
  U32

def f(b):
  match b:
    case True{}:
      100
    case False{}:
        7

law main.out:
  U32

def main.out():
  f(False{})

law main:
  IO(Unit)

def main():
  IO.print(U32.show(main.out()))

#|7
