# bend3 imports parsed anywhere in the file; bend imports are leading
# lines only, by design -- one after a def dies at parse
import Base

law f:
  for x: U32
  U32

def f(x):
  x

import /late/mod.bend as L

law main:
  U32

def main():
  0

#|Error:
#|- expected : 'def', 'type' or 'law'
#|- observed : 'i'
#|Location:
#|11 | 
#|12>| import /late/mod.bend as L
#|13 |
#|exit 1
