# audit: a linear binder may be DISCARDED (used zero times). Lone means
# at-most-once (affine), not exactly-once: None <= Lone.
# ported from bend3
import Base

law main:
  @_:U32 -> U32

def main(): x => 7

#|x => 7
