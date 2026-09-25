# a def that fills a law declares no return type: its text is bare names,
# and a "->" after them is refused at the missing ':', so a fill cannot
# state a type other than the law's
law claim:
  for n: Nat
  {n == n : Nat}

def claim(n) -> {0n == 1n : Nat}:
  {==}

#|Error:
#|- expected : ':'
#|- observed : '-'
#|Location:
#|7 | 
#|8>| def claim(n) -> {0n == 1n : Nat}:
#|  |              ^
#|9 |   {==}
#|exit 1
