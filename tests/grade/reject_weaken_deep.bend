type Nat is Data:
  Zero{}
  Succ{pred: Nat}

type Empty is Data:

type Sigma<a, b, -A: Kind(a), -B: @-x: A -> Kind(b)> is Kind(a <&> b):
  Tuple{fst: A, snd: B(fst)}

type List<a, -A: Kind(a)> is Kind(a):
  Nil{}
  Con{head: A, tail: List<a, A>}
# a quantity under two domains does not weaken either: a fit weakens a
# quantity only outside every domain, as the kernel does
type Dbl<a> is Type:
  Dbl{f: (List<a, Nat> -> Nat) -> Nat}

law dbl:
  for d: Dbl<&2>
  Dbl<&1>

def dbl(d):
  d

#|SOME PROOFS FAIL
#|Error:
#|- expected : Dbl<&1>
#|- observed : Dbl<&2>
#|Context:
#|- d : Dbl<&2>
#|Location: dbl
#|22 | def dbl(d):
#|23>|   d
#|   |   ^
#|24 | 
#|exit 1
