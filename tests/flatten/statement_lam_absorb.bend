# bend3's eta-absorption pin buried a numeric match-lambda tail under
# a statement; bend has no numeric match-lambda -- the tail's own
# spelling dies at parse, before any absorption question
import Base

type P8a is Data:
  P8a{a: U32, b: U32}

law eat:
  for p: P8a
  for x: U32
  U32

def eat(p, x):
  match p:
    case P8a{a, b}:
      ((x + a) .^. b : U32)

law mkm:
  for k: U32
  U32 -> U32

def mkm(k):
  p = {P8a{k, (k + 1 : U32)} : P8a}
  \{0: eat(p, 7); n => eat(p, n)}

law main:
  U32

def main():
  0

#|Error:
#|- expected : '}'
#|- observed : ':'
#|Location:
#|24 |   p = {P8a{k, (k + 1 : U32)} : P8a}
#|25>|   \{0: eat(p, 7); n => eat(p, n)}
#|26 |
#|exit 1
