type Nat is Data:
  Zero{}
  Succ{pred: Nat}

type Empty is Data:

type Sigma<a, b, -A: Kind(a), -B: @-x: A -> Kind(b)> is Kind(a <&> b):
  Tuple{fst: A, snd: B(fst)}

type List<a, -A: Kind(a)> is Kind(a):
  Nil{}
  Con{head: A, tail: List<a, A>}

# a datatype declares a kind, not any type
type Foo is Nat:
  MkFoo{}

#|Error:
#|- expected : a kind (type Foo<..> is Kind(g))
#|- observed : Nat
#|Location: Foo
#|14 | # a datatype declares a kind, not any type
#|15>| type Foo is Nat:
#|   |             ^^^
#|16 |   MkFoo{}
#|exit 1
