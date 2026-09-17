# the sharing-and-ordering leaves of base's text surface, distilled:
# one word read twice through a + binder and one three-way comparison
import Base

law main.out:
  U32

law main.fin:
  for b: U32
  for c: Cmp
  U32

def main.fin(b, c):
  match c:
    case LT{}:
      U32.add(b, 1)
    case EQ{}:
      0
    case GT{}:
      1

law main.cpy:
  for +w: U32
  U32

def main.cpy(w):
  main.fin(w, U32.cmp(w, 22))

def main.out():
  main.cpy(21)

law main:
  IO(Unit)

def main():
  IO.print(U32.show(main.out()))

#|22
