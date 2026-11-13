type Nat is Data:
  Zero{}
  Succ{pred: Nat}

type Empty is Data:

type Sigma<a, b, -A: Kind(a), -B: @-x: A -> Kind(b)> is Kind(a <&> b):
  Tuple{fst: A, snd: B(fst)}

type List<a, -A: Kind(a)> is Kind(a):
  Nil{}
  Con{head: A, tail: List<a, A>}
# a quantity under a domain does not weaken: a Use<&2> may copy the
# list it is given, so it is not a Use<&1>, which may be given an
# affine one
type Use<a> is Type:
  Use{f: List<a, Nat> -> Nat}

law use:
  for u: Use<&2>
  Use<&1>

def use(u):
  u

#|SOME PROOFS FAIL
#|Error:
#|- expected : Use<&1>
#|- observed : Use<&2>
#|Context:
#|- u : Use<&2>
#|Location: use
#|23 | def use(u):
#|24>|   u
#|   |   ^
#|25 | 
#|exit 1
