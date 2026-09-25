# bend3's Op2 probe-reuse pin applied a NUMERIC match-lambda as the
# left operand; bend match-lambdas take constructor keys only, so the
# probe's spelling dies at parse on the 0: key
import Base

law f:
  for n: U32
  for y: U32
  U32

def f(n, y):
  (\{0: 7; k => (k * 2 : U32)}(n : U32) + y : U32)

law main:
  U32

def main():
  (f(0, 1) * 100 + f(5, 1) : U32)

#|Error:
#|- expected : '}'
#|- observed : ':'
#|Location:
#|11 | def f(n, y):
#|12>|   (\{0: 7; k => (k * 2 : U32)}(n : U32) + y : U32)
#|   |       ^
#|13 |
#|exit 1
