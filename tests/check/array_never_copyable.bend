# slab-array pin (check_array_never_copyable): bend3 held arrays
# linear, never Data -- over-using an array binder was BadUsage. bend
# has no [:T] array type -- the [: spelling in dupa's parameter pins
# bend's own parse refusal (bend's own affine wall on every type is
# pinned by the capture twins).
import Base

type APair<-E: Type> is Type:
  AP{x: E, y: E}

law dupa:
  for a: [:U32]
  APair<[:U32]>

def dupa(a):
  AP{a, a}

law arr:
  [:U32]

def arr():
  ![_:0; 1]

law main:
  APair<[:U32]>

def main():
  dupa(arr())

#|Error:
#|- expected : a term
#|- observed : ':'
#|Location:
#|11 | law dupa:
#|12>|   for a: [:U32]
#|   |           ^
#|13 |   APair<[:U32]>
#|exit 1
