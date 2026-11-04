type Nat is Data:
  Zero{}
  Succ{pred: Nat}

type Empty is Data:

type Sigma<a, b, -A: Kind(a), -B: @-x: A -> Kind(b)> is Kind(a <&> b):
  Tuple{fst: A, snd: B(fst)}

type List<a, -A: Kind(a)> is Kind(a):
  Nil{}
  Con{head: A, tail: List<a, A>}
# a parameter a field uses both ways fits only itself: Bad<A> takes a
# Bad<A>, so it uses A against its own direction too
type Bad<-A: Type> is Type:
  Bad{f: Bad<A> -> A}

law bad:
  for b: Bad<List<&2, Nat>>
  Bad<List<&1, Nat>>

def bad(b):
  b

#|SOME PROOFS FAIL
#|Error:
#|- expected : Bad<List<&1, Nat>>
#|- observed : Bad<List<&2, Nat>>
#|Context:
#|- b : Bad<List<&2, Nat>>
#|Location: bad
#|22 | def bad(b):
#|23>|   b
#|   |   ^
#|24 | 
#|exit 1
