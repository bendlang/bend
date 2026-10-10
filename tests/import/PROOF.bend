# a PROOF.bend fails when a law relies on unsafe code: its error lists
# the law and its own @unsafe def, but not the imported one no law names
# (#1463), which tests/proof/PROOF.bend notes on a pass
import Base
import ./LAWS.bend as Laws

def lie?() -> {1n == 0n : Nat}:
  lie()

def Laws.false_law():
  lie()

#|SOME PROOFS FAIL
#|Error: 2 defs rely on unsafe or foreign code:
#|- LAWS.false_law
#|- lie
#|exit 1
