# audit: an equality hypothesis may be eliminated to produce a relevant
# proof. This is sound hypothetical reasoning -- "assuming 0=1, prove 0=1" -- not
# a closed proof of 0=1: `bad` can never be applied (its argument is uninhabited).
# The hypothesis binds Lone: a rewrite premise is LIVE (it runs to {==}).
# ported from bend3: explicit motive {0 == _}; base Unit replaces the local one
import Base

law bad:
  @e: {0 == 1 : U32} -> {0 == 1 : U32}

def bad(): e => %e : {0 == _ : U32}; {==}

law main:
  Unit

def main(): Unit{}

#|Unit{}
