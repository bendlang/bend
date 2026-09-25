# bend3's absent-slab static default and the page-walking drop;
# bend's Array has neither slabs nor defaults -- the sparse defaulted
# slab literal's spelling is the refusal
import Base

type P5 is Data:
  P5{a: U32, b: U32}
  N5{}

law main:
  U32

def main():
  m = (![0:P5{1,2}, 100000:P5{3,4}, _:N5{}; 131072] : [:P5])
  0

#|Error:
#|- expected : a term
#|- observed : '!'
#|Location:
#|13 | def main():
#|14>|   m = (![0:P5{1,2}, 100000:P5{3,4}, _:N5{}; 131072] : [:P5])
#|   |        ^
#|15 |   0
#|exit 1
