# rewriting by an equation whose CARRIER is a function type: the motive
# binds the function and congruence-at-an-argument falls out.
# ported from bend3: the motive is explicit -- _ marks g's occurrence
import Base

law ap_eq:
  for f: U32 -> U32
  for g: U32 -> U32
  for e: {f == g : U32 -> U32}
  {f(3) == g(3) : U32}

def ap_eq(f, g, e):
  %e : {f(3) == _(3) : U32}
  {==}

#|All terms check.
