# refusal pin: bend3's --no-halt door let use2 duplicate a value of the
# FORWARD datatype D, and the pin was that an unchecked datatype must
# never certify Data-ness. bend has no --no-halt door: names resolve
# upward only in a strict file, so the forward D3 in Two's field is
# itself the refusal -- the duplication in use2 is never weighed.
# ported from bend3: the Pair.Pair redefinition half is pinned by
# check_data_table_checked_000 (the duplicate-declaration wall)
import Base

type Two is Type:
  MkTwo{a: D3<U32>, b: D3<U32>}

law use2:
  for x: D3<U32>
  Two

def use2(x):
  MkTwo{x, x}

type D3<-result: Type> is Type:
  MkD3{fun: D3<result> -> result}

law main:
  U32

def main(): 0

#|Error:
#|- message  : a declared datatype (unknown: D3)
#|Location: MkTwo
#|10 | type Two is Type:
#|11>|   MkTwo{a: D3<U32>, b: D3<U32>}
#|12 |
#|exit 1
