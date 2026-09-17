# an axiom (bodiless assert) is a DEAD claim: the rewrite below needs
# live evidence, so validation refuses the use, not the claim.
# ported from bend3: bend3 admitted axioms in later proofs with a
# warning; bend pins the refusal (rewrite evidence is live)
import Base

law plus_comm:
  for a: U32
  for b: U32
  {U32.add(a, b) == U32.add(b, a) : U32}

law shift:
  for a: U32
  for b: U32
  {U32.add(U32.add(a, b), 0) == U32.add(U32.add(b, a), 0) : U32}

def shift(a, b):
  %h@plus_comm(a, b) : {U32.add(_, 0) == U32.add(U32.add(b, a), 0) : U32}; {==}

law main:
  U32

def main(): 0

#|Error:
#|- expected : a filled definition (an unfilled law is a dead claim: live code cannot use it)
#|- observed : plus_comm
#|Context:
#|- a : U32
#|- b : U32
#|Location: shift
#|17 | def shift(a, b):
#|18>|   %h@plus_comm(a, b) : {U32.add(_, 0) == U32.add(U32.add(b, a), 0) : U32}; {==}
#|19 |
#|exit 1
