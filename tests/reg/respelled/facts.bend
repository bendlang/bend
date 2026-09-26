# a module of tests/import/respelled_*: it reaches their core from outside
# tests/import, so from there its path spells that file a second way
import Base
import ../../import/respelled/core.bend as C

def seven_again() -> Nat:
  C.seven()
