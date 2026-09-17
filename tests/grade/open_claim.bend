type Nat is Data:
  Zero{}
  Succ{pred: Nat}

type Empty is Data:

type Sigma<a, b, -A: Kind(a), -B: @-x: A -> Kind(b)> is Kind(a <&> b):
  Tuple{fst: A, snd: B(fst)}

type List<a, -A: Kind(a)> is Kind(a):
  Nil{}
  Con{head: A, tail: List<a, A>}

# an unfilled assert claiming Data is an open claim: dead, a TODO
law bogus:
  Data

law main:
  Nat

def main():
  Zero{}

#|Error: 1 TODO found.
#|The code is incomplete, and not a valid proof yet.
#|exit 1
