# Local String.eq is distinct from Base's. This imported bend3 example
# remains invalid: its datatype declaration lacks `is Type` or `is Data`.
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

#|SOME PROOFS FAIL
#|Error:
#|- expected : 'is'
#|- observed : ':'
#|Location:
#|12 |
#|13>| type D2<result: Type>:
#|   |                      ^
#|14 |   MkD2{fun: D2<result> -> result}
#|exit 1
