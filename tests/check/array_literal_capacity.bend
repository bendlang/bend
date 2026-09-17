# slab-array pin (check_array_literal_capacity): bend3's entry-less
# literal [_:d; n] capped capacity at the declared n, past-capacity
# writes no-oping to the default. bend has no array literals -- the
# ![ spelling pins bend's own parse refusal.
import Base

law go:
  for a: U32
  U32

def go(a):
  old = ![_:9; 1]@m[0] <- 5
  x = m@m2[0]
  w = m2@m3[1] <- 77
  (x + old + w + a : U32)

law main:
  U32

def main():
  go(7)

#|Error:
#|- expected : a term
#|- observed : '!'
#|Location:
#|11 | def go(a):
#|12>|   old = ![_:9; 1]@m[0] <- 5
#|13 |   x = m@m2[0]
#|exit 1
