# regression witness (d580b83 residue): keeping a binder at an ERASED
# type variable. SPEC 1.2 makes sharing generic over terms (a redirect
# and a count; no deep cloner exists), and the checker admits x twice
# through +x: A over an erased Data variable, the + binder serving the
# generic type strict, yet tocl refuses the emission because the refcount
# decision is keyed on a concrete datatype. d580b83 freed kept CLOSURE
# binders; the generic case is the seam still standing.
import Base

type Box is Data:
  Bx{v: U32}

law peek:
  for b: Box
  U32

def peek(b):
  match b:
    case Bx{v}:
      v

law dup:
  for -A: Data
  for +x: A
  for  f: @a: A -> @b: A -> U32
  U32

def dup(A, x, f):
  f(x)(x)

law main.out:
  U32

def main.out():
  dup(Box, Bx{21}, a => b => U32.add(peek(a), peek(b)))

law main:
  IO(Unit)

def main():
  IO.print(U32.show(main.out()))

#|42
