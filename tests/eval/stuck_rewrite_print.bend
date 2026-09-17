# a rewrite stuck on an OPAQUE premise prints back as % with its
# motive, under the open binders.
# ported from bend3: bend's motive is a term over _ (no lambda
# motive), and the def body moves under lambdas in main (an unapplied
# def stays closed)
import Base

law main:
  @a:U32 -> @b:U32 -> @e:{a == b : U32} -> {b == a : U32}

def main():
  a => b => e => (%e : {_ == a : U32}; {==})

#|a => b => e => %e : {_ == a : U32}; {==}
