# a ?TODO in a group's annotation is one hole each: the body's try at a
# typed let reads the type and goes back, and the hole it met is not
# counted. The second type holds an `=`, in `<=`
import Base

def main() -> U32:
  U32.add((7 : ?TODO), (7 : ?TODO <= U32))

#|SOME PROOFS FAIL
#|Error: 2 TODOs found.
#|The code is incomplete, and not a valid proof yet.
#|exit 1
