# bend3 glued the GPU mark before type arguments (pick<A>!(x)); bend
# defs take no <> type arguments at all (def<A> generics are ruled
# out: they collide with infix <), so the declaration dies first
import Base

law pick:
  for -A: Type
  for x: A
  for y: A
  A

def pick<A>(x, y):
  y

law main:
  U32

def main():
  pick<U32>!(1, 2)

#|Error:
#|- expected : '('
#|- observed : '<'
#|Location:
#|11 | 
#|12>| def pick<A>(x, y):
#|13 |   y
#|exit 1
