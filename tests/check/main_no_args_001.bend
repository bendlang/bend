# a PURE main taking parameters is a COMPILE-time refusal: the compiled
# driver calls main with no arguments. The interpreter merely prints
# the stuck underapplied ref.
# ported from bend3
import Base

law main:
  for x: U32
  U32

def main(x):
  U32.add(x, 1)

#|x => U32.add(x, 1)
