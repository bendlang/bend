# a fill states no type, not even Quant: 'n: Quant' used to be accepted
# and ignored, n keeping the law's Nat
import Base

law claim:
  for n: Nat
  {n == n : Nat}

def claim(n: Quant):
  {==}

#|SOME PROOFS FAIL
#|Error:
#|- expected : bare parameter names and no '->' (def claim fills a law, which gives the types)
#|- observed : ':'
#|Location:
#| 8 | 
#| 9>| def claim(n: Quant):
#|   |            ^
#|10 |   {==}
#|exit 1
