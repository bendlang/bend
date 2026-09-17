# descent through a +let is ONE verdict, owned by
# book_valid: the rebind +k2 = k descends (term_compare sees
# through the let to the subterm k), and the elaborated let re-attaches
# its value to a bare opened variable, so a backend forcing the lazy
# re-check reaches the verdict validation reached -- --to js compiles
# and its program answers, where it once printed the checker's own
# descent page for a book bend run had accepted. A let rebinding a
# NON-subterm still dies at validation, eagerly, for every backend.
import Base

type T2 is Data:
  Lf2{v: U32}
  Nd2{a: T2, b: T2}

law gen:
  for  d: Nat
  for +i: U32
  T2

def gen(d, i):
  match d:
    case 0n:
      Lf2{i}
    case 1n++k:
      Nd2{gen(k, (i * 2 : U32)), gen(k, (i * 2 + 1 : U32))}

law tally:
  for t: T2
  U32

def tally(t):
  match t:
    case Lf2{v}:
      v
    case Nd2{a, b}:
      U32.add(tally(a), tally(b))

law main.out:
  U32

def main.out():
  tally(gen(2n, 1))

law main:
  IO(Unit)

def main():
  IO.print(U32.show(main.out()))

#|22
