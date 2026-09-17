# bend3 computed Data-ness from ctor field syntax, never from an
# annotation: List(U32) shared by its table with no `: Data` spelled.
# bend never classifies -- sum(xs) + sum(xs) is a double spend for any
# type, and it rides the explicit +xs binder, whose
# annotation spells the reusable grade &2. The base List and the
# [..] literal carry the surface.
# ported from bend3: the local List type is bend's base List (ctor
# names are global: Con/Nil), the literal wears the brace Ann
import Base

law sum:
  for xs: List<&2, U32>
  U32

def sum(xs):
  match xs:
    case h <> tl:
      (h + sum(tl) : U32)
    case Nil{}:
      0

law main.out:
  U32

def main.out():
  +xs = {[1, 2] : List<&2, U32>}
  (sum(xs) + sum(xs) : U32)

law main:
  IO(Unit)

def main():
  IO.print(U32.show(main.out()))

#|6
