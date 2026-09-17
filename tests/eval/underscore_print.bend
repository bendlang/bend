# non-dependent arrow binders do not capture source '_': the wildcard
# lambda prints back as _ with its constant body.
# ported from bend3: the body becomes 0n for a readable golden
import Base

law main:
  @x:U32 -> Nat

def main():
  _ => 0n

#|_ => 0n
