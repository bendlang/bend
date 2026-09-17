# bend3's `match a!` computed opt-out mark (ironically named for
# bend's parser); bend's own ! is the GPU bang before a call's
# parens and no scrutinee mark exists -- the spelling dies at parse
import Base

law f:
  for n: Nat
  Nat

def f(n):
  match n!:
    case Zero{}:
      0n
    case Succ{p}:
      1n

law main:
  Nat

def main():
  f(2n)

#|Error:
#|- expected : a term
#|- observed : '!'
#|Location:
#|10 | def f(n):
#|11>|   match n!:
#|12 |     case Zero{}:
#|exit 1
