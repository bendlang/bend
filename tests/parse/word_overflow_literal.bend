# audit: integer literals beyond 2^32-1 are a parse error, not a wrap.
# ported from bend3
import Base

law main:
  U32

def main(): 4294967296

#|Error:
#|- expected : a u32 literal up to 4294967295 (got 4294967296)
#|- observed : '
#|'
#|Location:
#|7 | 
#|8>| def main(): 4294967296
#|9 |
#|exit 1
