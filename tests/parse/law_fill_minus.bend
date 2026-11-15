# a fill's parameter takes no quantity: a '-' is refused where it is
# written (it used to ask for a ':' at the ')')
law claim:
  for n: Nat
  {n == n : Nat}

def claim(-n):
  {==}

#|SOME PROOFS FAIL
#|Error:
#|- expected : bare parameter names and no '->' (def claim fills a law, which gives the types)
#|- observed : '-'
#|Location:
#|6 | 
#|7>| def claim(-n):
#|  |           ^
#|8 |   {==}
#|exit 1
