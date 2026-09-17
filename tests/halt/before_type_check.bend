# audit: a nullary def applying itself errors at the def, before main is
# ever looked at -- the descent judgment lives inside infer-app, so the
# self-application is refused as non-decreasing (no column shrinks).
# ported from bend3: U32 becomes Nat; bend3 pinned its separate halt
# phase beating a later type error, bend pins the in-checker ordering
import Base

law bad:
  Nat

def bad(): bad(0n)
law main:
  Nat

def main(): 0n

#|Error:
#|- expected : a decreasing self-call (arguments are read left to right: each passed unchanged until one shrinks)
#|- observed : bad
#|Location: bad
#|10 | 
#|11>| def bad(): bad(0n)
#|12 | law main:
#|exit 1
