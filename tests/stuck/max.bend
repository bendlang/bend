# U32.max opens both words before it copies them, so on stuck words it
# stays one call: n nested maxes print n calls, where a max that copied
# first unfolded to 2^n picks (#1075).
import Base

law main:
  @+a:U32 -> @+b:U32 -> U32

def main():
  a => b => U32.max(U32.max(a, b), b)

#|a => b => U32.max(U32.max(a, b), b)
