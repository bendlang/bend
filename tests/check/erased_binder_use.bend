# audit 001: an erased lambda binder cannot be used in the body.
# ported from bend3: --> becomes the erased all @-x
import Base

law main:
  @-x:U32 -> U32

def main(): x => x

#|Error:
#|- expected : -x
#|- observed : x
#|Location: main
#|7 | 
#|8>| def main(): x => x
#|9 |
#|exit 1
