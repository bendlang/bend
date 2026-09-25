# bend3's pin that fuel is dead: an inline dep match over a literal
# depth computes at check time. bend never had fuel, and the staging
# spelling itself is ruled out -- the countdown's `1+d` pattern does
# not exist on the wrapper U32; the port dies at the pattern
import Base

law stack:
  for d: U32
  for h: U32
  U32

def stack(d, h):
  match d:
    case 0:
      h
    case 1+d:
      stack(d, (h * 5 : U32))

law dep:
  for s: U32
  {stack(5, s) == stack(5, s) : U32}

def dep(s):
  {==}

law main:
  U32

def main():
  0

#|Error:
#|- expected : 1 patterns (one per scrutinee)
#|- observed : '1+d'
#|Location:
#|15 |       h
#|16>|     case 1+d:
#|   |          ^^^
#|17 |       stack(d, (h * 5 : U32))
#|exit 1
