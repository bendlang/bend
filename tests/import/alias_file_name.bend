# an alias may spell its file's own name: run alone, this file's
# neighbour alias_lib is namespace alias_lib, so alias_lib.two names one
# def both ways and is no shadow
import Base
import ./alias_lib.bend as alias_lib

def main() -> Nat:
  alias_lib.two()

#|2n
