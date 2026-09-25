type Nat is Data:
  Zero{}
  Succ{pred: Nat}

type Empty is Data:

type Sigma<a, b, -A: Kind(a), -B: @-x: A -> Kind(b)> is Kind(a <&> b):
  Tuple{fst: A, snd: B(fst)}

type List<a, -A: Kind(a)> is Kind(a):
  Nil{}
  Con{head: A, tail: List<a, A>}

# a List<&1, Nat> is not a List<&2, Nat>: no view weakens up
law up:
  for xs: List<&1, Nat>
  List<&2, Nat>

def up(xs):
  xs

#|Error:
#|- expected : List<&2, Nat>
#|- observed : List<&1, Nat>
#|Context:
#|- xs : List<&1, Nat>
#|Location: up
#|19 | def up(xs):
#|20>|   xs
#|   |   ^^
#|21 | 
#|exit 1
