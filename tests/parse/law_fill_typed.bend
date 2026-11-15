# a def that fills a law takes bare names. Written with a full signature,
# as any other def is, it is refused at the first ':' and told why (it
# used to ask for a name at the '->')
law claim:
  for n: Nat
  {n == n : Nat}

def claim(n: Nat) -> {n == n : Nat}:
  {==}

#|SOME PROOFS FAIL
#|Error:
#|- expected : bare parameter names and no '->' (def claim fills a law, which gives the types)
#|- observed : ':'
#|Location:
#|7 | 
#|8>| def claim(n: Nat) -> {n == n : Nat}:
#|  |            ^
#|9 |   {==}
#|exit 1
