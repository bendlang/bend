# bend3's dead %[x => P] motive spelling died as list syntax; bend's
# rewrite is `%e : P` and [ after % has no reading at all -- the old
# spelling dies at parse
import Base

law sym3:
  for -x: U32
  for -y: U32
  for e: {x == y : U32}
  {y == x : U32}

def sym3(x, y, e):
  %[h => {y == h : U32}] e {=}

law main:
  U32

def main():
  0

#|Error:
#|- expected : ':'
#|- observed : 'e'
#|Location:
#|12 | def sym3(x, y, e):
#|13>|   %[h => {y == h : U32}] e {=}
#|14 |
#|exit 1
