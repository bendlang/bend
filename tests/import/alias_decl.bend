# a declaration may not start with an import's alias unless it fills
# that import's law: M.three was this file's own, reached as M.three only
# while the module had no three of its own
import Base
import ./alias_lib.bend as M

def M.three() -> Nat:
  3n

def main() -> Nat:
  M.three()

#|Error:
#|- expected : a fresh name (M is an import's alias)
#|- observed : 'M.three'
#|Location:
#|6 |
#|7>| def M.three() -> Nat:
#|  |     ^^^^^^^
#|8 |   3n
#|exit 1
