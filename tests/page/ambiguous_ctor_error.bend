# a ctor tag with two owners: bend ctors are bare and globally
# unique, so the second owner is refused AT DECLARATION (bend3 nulled
# the bare tag at use instead; the one-owner law carries)
type A is Data:
  K{a: U32}

type B is Data:
  K{a: U32, b: U32}

law f:
  for v: A
  U32

def f(v):
  match v:
    case K{a}:
      a

law main:
  U32

def main(): f(K{1})

#|Error:
#|- expected : a fresh constructor name (duplicate declaration: K)
#|- observed : 'K'
#|Location:
#|7 | type B is Data:
#|8>|   K{a: U32, b: U32}
#|  |   ^
#|9 |
#|exit 1
