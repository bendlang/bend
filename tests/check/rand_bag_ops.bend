# bend3's Rand/Bag modules (a PRNG feeding a multiset) are absent from
# bend's base: the head call is an undefined name
import Base

law main:
  U32

def main():
  Rand.next(Rand.new(42))

#|Error:
#|- expected : a defined name
#|- observed : Rand.next
#|Location: main
#| 8 | def main():
#| 9>|   Rand.next(Rand.new(42))
#|   |   ^^^^^^^^^
#|10 |
#|exit 1
