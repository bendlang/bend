type Nat is Data:
  Zero{}
  Succ{pred: Nat}

type Empty is Data:

type Sigma<a, b, -A: Kind(a), -B: @-x: A -> Kind(b)> is Kind(a <&> b):
  Tuple{fst: A, snd: B(fst)}

type List<a, -A: Kind(a)> is Kind(a):
  Nil{}
  Con{head: A, tail: List<a, A>}

# a header grade a cannot entail a sibling grade b
type T<a, b, -A: Kind(a), -B: Kind(b)> is Kind(a):
  C{x: B}

#|Error:
#|- expected : Kind(a)
#|- observed : Kind(b)
#|Context:
#|- a : Quant
#|- b : Quant
#|- A : Kind(a)
#|- B : Kind(b)
#|Location: C
#|15 | type T<a, b, -A: Kind(a), -B: Kind(b)> is Kind(a):
#|16>|   C{x: B}
#|   |        ^
#|17 | 
#|exit 1
