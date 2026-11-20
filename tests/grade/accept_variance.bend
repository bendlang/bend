type Nat is Data:
  Zero{}
  Succ{pred: Nat}

type Empty is Data:

type Sigma<a, b, -A: Kind(a), -B: @-x: A -> Kind(b)> is Kind(a <&> b):
  Tuple{fst: A, snd: B(fst)}

type List<a, -A: Kind(a)> is Kind(a):
  Nil{}
  Con{head: A, tail: List<a, A>}
# a fit reads each datatype parameter's variance off the fields: a
# reusable list fits an affine one, inside a list, a rose tree and a
# mutual family that keep it covariant, and inside a predicate that
# takes it, which turns the fit around
type Rose<a, -A: Kind(a)> is Kind(a):
  Rose{val: A, kids: List<a, Rose<a, A>>}

type Tm<-A: Type> is Type:
  Leaf{name: A}
  Fork{arms: Arms<A>}

type Arms<-A: Type> is Type:
  ANil{}
  ACon{head: Tm<A>, tail: Arms<A>}

type Pred<-A: Type> is Type:
  Pred{f: A -> Nat}

law down:
  for xs: List<&2, Nat>
  List<&1, Nat>

def down(xs):
  xs

law nested:
  for xs: List<&2, List<&2, Nat>>
  List<&1, List<&1, Nat>>

def nested(xs):
  xs

law rose:
  for t: Rose<&2, List<&2, Nat>>
  Rose<&1, List<&1, Nat>>

def rose(t):
  t

law tm:
  for t: Tm<List<&2, Nat>>
  Tm<List<&1, Nat>>

def tm(t):
  t

law pred:
  for p: Pred<List<&1, Nat>>
  Pred<List<&2, Nat>>

def pred(p):
  p

law main:
  List<&1, Nat>

def main():
  down([1n, 2n])

#|[1n, 2n]
