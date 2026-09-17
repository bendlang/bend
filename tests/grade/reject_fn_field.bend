type Nat is Data:
  Zero{}
  Succ{pred: Nat}

type Empty is Data:

type Sigma<a, b, -A: Kind(a), -B: @-x: A -> Kind(b)> is Kind(a <&> b):
  Tuple{fst: A, snd: B(fst)}

type List<a, -A: Kind(a)> is Kind(a):
  Nil{}
  Con{head: A, tail: List<a, A>}

# a live function field refuses a Data declaration
type Box is Data:
  MkBox{f: Nat -> Nat}

#|Error:
#|- expected : Data
#|- observed : Type
#|Location: MkBox
#|15 | type Box is Data:
#|16>|   MkBox{f: Nat -> Nat}
#|17 |
#|exit 1
