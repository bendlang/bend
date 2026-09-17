# a destructure's value rides an annotated call argument: a wrong
# annotation is a type error, not a no-op.
# ported from bend3: `P = e : T` spells the Ann brace at the call
import Base

type Pw2 is Data:
  Pq2{a: U32, b: U32}

type Bw7 is Data:
  Tw7{}

law swap:
  for p: Pw2
  Pw2

law swap.go:
  for q: Pw2
  Pw2

def swap.go(q):
  Pq2{x, y} = q
  Pq2{y, x}

def swap(p):
  swap.go({p : Bw7})

law main:
  Pw2

def main(): swap(Pq2{1, 2})

#|Error:
#|- expected : Bw7
#|- observed : Pw2
#|Context:
#|- p : Pw2
#|Location: swap
#|24 | def swap(p):
#|25>|   swap.go({p : Bw7})
#|26 | 
#|exit 1
