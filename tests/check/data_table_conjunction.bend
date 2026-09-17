# audit carried: bend3's Pair table was [0, 1] -- Data iff both
# arguments are -- so Pair(U32, U32) shared. the grade kernel spells
# that table as the declared kind: Pr7<a, b, ..> -> Kind(a <&> b) is
# Data iff both grades are &2, so Pr7<&2, &2, U32, U32> binds + and
# a double spend builds, matches and answers 84 (42 twice).
# ported from bend3: type Pair(A: Data, B: Data) -> type Pr7<a, b,
# -A: Kind(a), -B: Kind(b)> -> Kind(a <&> b); the let-then-match main
# routes through get
import Base

type Pr7<a, b, -A: Kind(a), -B: Kind(b)> is Kind(a <&> b):
  MkPr7{x: A, y: B}

law get:
  for p: Pr7<&2, &2, U32, U32>
  U32

def get(p):
  match p:
    case MkPr7{x, y}:
      (x + y : U32)

law get2:
  for +p: Pr7<&2, &2, U32, U32>
  U32

def get2(p):
  (get(p) + get(p) : U32)

law main.out:
  U32

def main.out():
  get2({MkPr7{20, 22} : Pr7<&2, &2, U32, U32>})

law main:
  IO(Unit)

def main():
  IO.print(U32.show(main.out()))

#|84
