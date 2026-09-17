# negative recursive data plus contraction builds a closed proof of
# Empty (delta(DCon{f}) = f(DCon{f}) needs f twice) -- the attack
# spells as bare over-use of the field and linearity rejects it.
# ported from bend3
type Dm<-A: Type> is Type:
  DCon{f: Dm<A> -> A}

law delta:
  for -A: Type
  for d: Dm<A>
  A

def delta(A, d):
  match d:
    case DCon{f}:
      f(DCon{f})

law main:
  Type

def main(): Type

#|Error:
#|- expected : f
#|- observed : f (consumed more than once)
#|Context:
#|- A : Type
#|Location: delta
#|14 |   match d:
#|15>|     case DCon{f}:
#|16 |       f(DCon{f})
#|exit 1
