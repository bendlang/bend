type Nat is Data:
  Zero{}
  Succ{pred: Nat}

type Empty is Data:

type Sigma<a, b, -A: Kind(a), -B: @-x: A -> Kind(b)> is Kind(a <&> b):
  Tuple{fst: A, snd: B(fst)}

type List<a, -A: Kind(a)> is Kind(a):
  Nil{}
  Con{head: A, tail: List<a, A>}

# a resource declared Type stays affine whatever its fields hold
type Res is Type:
  MkRes{n: Nat}

law dupr:
  for +r: Res
  Nat

def dupr(r):
  Zero{}

#|Error:
#|- expected : Data
#|- observed : Type
#|Location: dupr
#|18 | law dupr:
#|19>|   for +r: Res
#|   |           ^^^
#|20 |   Nat
#|exit 1
