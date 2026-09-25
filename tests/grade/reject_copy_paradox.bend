type Nat is Data:
  Zero{}
  Succ{pred: Nat}

type Empty is Data:

type Sigma<a, b, -A: Kind(a), -B: @-x: A -> Kind(b)> is Kind(a <&> b):
  Tuple{fst: A, snd: B(fst)}

type List<a, -A: Kind(a)> is Kind(a):
  Nil{}
  Con{head: A, tail: List<a, A>}

# the old Copy(T, x) = &y:T -> {x == y : T} was contractible with
# center (x, {==}) and licensed contraction of any T. as a datatype it
# must declare its kind, and a live field of kind Type is refused in a
# Data declaration: no live x hides behind its own reflexivity.
type Cp<-T: Type, -x: T> is Data:
  MkCp{y: T, e: {x == y : T}}

#|Error:
#|- expected : Data
#|- observed : Type
#|Context:
#|- T : Type
#|- x : T
#|Location: MkCp
#|18 | type Cp<-T: Type, -x: T> is Data:
#|19>|   MkCp{y: T, e: {x == y : T}}
#|   |           ^
#|20 | 
#|exit 1
