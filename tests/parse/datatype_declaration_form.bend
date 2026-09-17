# audit: the frozen datatype declaration form is type-headed, with params
# in ONE comma-separated angle group and shape-delimited ctor rows.
# ported from bend3: parens params become angles, ctors bare and unique,
# the literal scrutinee moves behind a def (bend refuses an
# undestructed ctor scrutinee)
type Pr<a, b, -A: Kind(a), -B: Kind(b)> is Kind(a <&> b):
  Mk{fst: A, snd: B}

type Nn2 is Data:
  Zz2{}
  Ss2{p: Nn2}

law fst_of:
  for p: Pr<&2, &2, Nn2, Nn2>
  Nn2

def fst_of(p):
  match p:
    case Mk{n, x}:
      n

law main:
  Nn2

def main():
  fst_of(Mk{Ss2{Ss2{Zz2{}}}, Zz2{}})

#|Ss2{Ss2{Zz2{}}}
