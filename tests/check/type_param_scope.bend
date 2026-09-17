# audit: datatype parameters remain available inside constructor field
# types.
# ported from bend3
import Base

type Dq<A: Type> is Type:
  Cq{f: @x:U32 -> A}

law main:
  U32

def main(): 0

#|0
