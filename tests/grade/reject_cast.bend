type Nat is Data:
  Zero{}
  Succ{pred: Nat}

type Empty is Data:

type Sigma<a, b, -A: Kind(a), -B: @-x: A -> Kind(b)> is Kind(a <&> b):
  Tuple{fst: A, snd: B(fst)}

type List<a, -A: Kind(a)> is Kind(a):
  Nil{}
  Con{head: A, tail: List<a, A>}

# Type does not convert into Data: a kind weakens only into Type
law cast:
  for -A: Type
  Data

def cast(A):
  A

#|Error:
#|- expected : Data
#|- observed : Type
#|Context:
#|- A : Type
#|Location: cast
#|19 | def cast(A):
#|20>|   A
#|21 | 
#|exit 1
