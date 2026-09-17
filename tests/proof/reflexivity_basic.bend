# reflexivity is the nullary {==}: it proves {a == b : T} when the sides convert.
# ported from bend3: U32 rides Base; the interpreter lane replaces --eval
import Base

law main:
  {0 == 0 : U32}

def main(): {==}

#|{==}
