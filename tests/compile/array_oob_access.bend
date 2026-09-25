# bend3's slab OOB laws (past-capacity writes no-op, OOB reads serve
# the static default); bend's Array<T> is a 2^d tree with wrapping
# bit-walk indexing -- no capacity, no default -- and the slab literal
# has no grammar: its spelling is the refusal
import Base

law main:
  U32

def main():
  wrd = (![0: 10, 1: 20, _: 7; 2] : [:U32])
  wrd@w1[5] <- 99

#|Error:
#|- expected : a term
#|- observed : '!'
#|Location:
#|10 | def main():
#|11>|   wrd = (![0: 10, 1: 20, _: 7; 2] : [:U32])
#|   |          ^
#|12 |   wrd@w1[5] <- 99
#|exit 1
