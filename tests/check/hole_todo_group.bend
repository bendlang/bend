# a ?TODO in a group's annotation is one hole: the type after the `:` is
# read once, so the hole is counted once
import Base

def main() -> U32:
  (7 : ?TODO)

#|SOME PROOFS FAIL
#|Error: 1 TODO found.
#|The code is incomplete, and not a valid proof yet.
#|exit 1
