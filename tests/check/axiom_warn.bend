# an assert never filled is an OPEN CLAIM: the checker validates the
# asserted type, keeps the entry dead, and counts it as a TODO (the
# CLI refuses the file, main or not). base.bend keeps its axioms (the
# bodiless-native idiom). Live use stays pinned by check_axiom_use.
# ported from bend3: bend3 warned one line per axiom and accepted
type Nz1 is Data:
  Zn1{}
  Sn1{p: Nz1}

law ghost:
  for x: Nz1
  Nz1

law main:
  Nz1

def main(): Zn1{}

#|Error: 1 TODO found.
#|The code is incomplete, and not a valid proof yet.
#|exit 1
