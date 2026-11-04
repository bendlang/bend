type Nat is Data:
  Zero{}
  Succ{pred: Nat}

type Empty is Data:

type Sigma<a, b, -A: Kind(a), -B: @-x: A -> Kind(b)> is Kind(a <&> b):
  Tuple{fst: A, snd: B(fst)}

type List<a, -A: Kind(a)> is Kind(a):
  Nil{}
  Con{head: A, tail: List<a, A>}
# a fit weakens a reusable datatype to an affine one when its fields
# only pass the quantity along: a list, the outer list of a list of
# lists (its elements keep theirs), and a bag that passes it to a list
type Bag<a, -A: Kind(a)> is Kind(a):
  Bag{items: List<a, A>}

law down:
  for xs: List<&2, Nat>
  List<&1, Nat>

def down(xs):
  xs

law outer:
  for xs: List<&2, List<&2, Nat>>
  List<&1, List<&2, Nat>>

def outer(xs):
  xs

law bag:
  for b: Bag<&2, Nat>
  Bag<&1, Nat>

def bag(b):
  b

law main:
  List<&1, Nat>

def main():
  down([1n, 2n])

#|[1n, 2n]
