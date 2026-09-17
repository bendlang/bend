# regression witness (10225ce): the compiler is a pure function of its
# input -- the borrow table once outlived compile_book, so the SECOND
# compilation in one process read the first book's stale rows and the
# minted continuation died 'unbound binder: t' on THIS shape: a
# let-bound t with two owners (lend and eat both take it; nothing
# borrows) across spin's cut. The runner's reg_compiler_pure row
# recompiles this file in-process and byte-compares the emissions.
import Base

type Bt is Data:
  Bl{v: U32}
  Bn{a: Bt, b: Bt}

law sum:
  for t: Bt
  U32

def sum(t):
  match t:
    case Bl{v}:
      v
    case Bn{a, b}:
      U32.add(sum(a), sum(b))

law spin:
  for +n: Nat
  U32

def spin(n):
  match n:
    case 0n:
      1
    case 1n+p:
      U32.add(1, spin(p))

law lend:
  for t: Bt
  U32

def lend(t):
  a = spin(3n)
  U32.add(a, sum(t))

law eat:
  for t: Bt
  U32

def eat(t):
  match t:
    case Bl{v}:
      v
    case Bn{a, b}:
      U32.add(eat(a), eat(b))

law main.out:
  U32

def main.out():
  +t = {Bn{Bn{Bl{1}, Bl{2}}, Bl{3}} : Bt}
  a = lend(t)
  U32.add(a, eat(t))

law main:
  IO(Unit)

def main():
  IO.print(U32.show(main.out()))

#|16
