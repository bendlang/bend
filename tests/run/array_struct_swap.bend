# bend3's slab default-serving through the swap form (old = m[i] <-
# new) on constructor elements; bend's Array serves no defaults and
# has no slab literal -- the defaulted ctor literal's spelling is the
# refusal (the in-range swap form is covered by the ported reg_array
# tests)
import Base

type Box9 is Data:
  Mk9{v: U32}

law main:
  U32

def main():
  m : [:Box9] = ![0:Mk9{1}, _:Mk9{7}; 1]
  a = m[0] <- Mk9{5}
  0

#|Error:
#|- expected : a term
#|- observed : ':'
#|Location:
#|14 | def main():
#|15>|   m : [:Box9] = ![0:Mk9{1}, _:Mk9{7}; 1]
#|   |        ^
#|16 |   a = m[0] <- Mk9{5}
#|exit 1
