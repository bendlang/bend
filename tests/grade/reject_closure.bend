type Nat is Data:
  Zero{}
  Succ{pred: Nat}

type Empty is Data:

type Sigma<a, b, -A: Kind(a), -B: @-x: A -> Kind(b)> is Kind(a <&> b):
  Tuple{fst: A, snd: B(fst)}

type List<a, -A: Kind(a)> is Kind(a):
  Nil{}
  Con{head: A, tail: List<a, A>}

# a function type is Type: a closure captures, so it is never reused
law dupf:
  for +f: Nat -> Nat
  Nat

def dupf(f):
  f(f(Zero{}))

#|Error:
#|- expected : Data
#|- observed : Type
#|Location: dupf
#|15 | law dupf:
#|16>|   for +f: Nat -> Nat
#|   |           ^^^^^^^^^^
#|17 |   Nat
#|exit 1
