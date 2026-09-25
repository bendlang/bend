type Nat is Data:
  Zero{}
  Succ{pred: Nat}

type Empty is Data:

type Sigma<a, b, -A: Kind(a), -B: @-x: A -> Kind(b)> is Kind(a <&> b):
  Tuple{fst: A, snd: B(fst)}

type List<a, -A: Kind(a)> is Kind(a):
  Nil{}
  Con{head: A, tail: List<a, A>}

# a recursive negative datatype stores a function: never Data
type Knot is Data:
  KRoll{run: Knot -> Empty}

#|Error:
#|- expected : Data
#|- observed : Type
#|Location: KRoll
#|15 | type Knot is Data:
#|16>|   KRoll{run: Knot -> Empty}
#|   |              ^^^^^^^^^^^^^
#|17 |
#|exit 1
