type Nat is Data:
  Zero{}
  Succ{pred: Nat}

type Empty is Data:

type Sigma<a, b, -A: Kind(a), -B: @-x: A -> Kind(b)> is Kind(a <&> b):
  Tuple{fst: A, snd: B(fst)}

type List<a, -A: Kind(a)> is Kind(a):
  Nil{}
  Con{head: A, tail: List<a, A>}
# a quantity passed back to its own slot under an arrow does not weaken
type Loop<a> is Type:
  Loop{f: Loop<a> -> Nat}

law loop:
  for l: Loop<&2>
  Loop<&1>

def loop(l):
  l

#|SOME PROOFS FAIL
#|Error:
#|- expected : Loop<&1>
#|- observed : Loop<&2>
#|Context:
#|- l : Loop<&2>
#|Location: loop
#|21 | def loop(l):
#|22>|   l
#|   |   ^
#|23 | 
#|exit 1
