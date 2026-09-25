# refusal pin: bend3's file redefined Pair.Pair to elaborate a raw
# tuple field into a function type, and its own golden was the
# duplicate-declaration refusal -- the negative-self-application Empty
# never checked. bend hits the same first wall: a Base name cannot be
# redeclared (and bend has no Data table for the redefinition to
# poison; the D/delta skeleton below the dying line is inert).
# ported from bend3: Pair.Pair -> String.eq (bend's base owns no
# Pair; the wall is the name, not the signature)
import Base

law String.eq:
  for a: String
  for b: String
  Bool

def String.eq(a, b):
  True{}

type D2<result: Type>:
  MkD2{fun: D2<result> -> result}

law delta:
  for -answer: Type
  for value: D2<answer>
  answer

def delta(answer, value):
  delta.go(value, value)

law delta.go:
  for -answer: Type
  for saved: D2<answer>
  for value: D2<answer>
  answer

def delta.go(answer, saved, value):
  match value:
    case MkD2{step}:
      step(saved)

law main:
  Empty

def main(): delta(Empty, MkD2{delta(Empty)})

#|Error:
#|- expected : a fresh name (duplicate declaration: String.eq)
#|- observed : 'String.eq'
#|Location:
#|10 | 
#|11>| law String.eq:
#|   |     ^^^^^^^^^
#|12 |   for a: String
#|exit 1
