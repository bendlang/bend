# slab-array pin (check_array_boxed_default): bend3 REJECTED a boxed
# (multi-word) ctor as an array-literal default -- defaults are served
# one-word constants. bend has no slab-array surface at all (base
# Array is a tree, tocl makes it real); the ![ literal pins bend's
# own parse refusal.
import Base

type P is Data:
  PW{a: U32, b: U32}

law val:
  for p: P
  U32

def val(p):
  match p:
    case PW{a, b}:
      (a + b : U32)

law main:
  U32

def main():
  h = (![0:PW{3,4}, _:PW{1,2}; 1] : [:P])
  x = h@h2[3] <- PW{0,0}
  val(x)

#|Error:
#|- expected : a term
#|- observed : '!'
#|Location:
#|23 | def main():
#|24>|   h = (![0:PW{3,4}, _:PW{1,2}; 1] : [:P])
#|25 |   x = h@h2[3] <- PW{0,0}
#|exit 1
