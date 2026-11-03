# proofs erase at compilation, so an axiom (bodiless assert) is dead:
# a live use of one refuses at validation on every lane, before any
# backend sees it (the open claim itself only counts as a TODO)
# ported from bend3
import Base

law magic:
  U32

law main:
  U32

def main():
  magic

#|SOME PROOFS FAIL
#|Error:
#|- expected : a def whose body is implemented before the def is used
#|- observed : magic
#|Location: main
#|13 | def main():
#|14>|   magic
#|   |   ^^^^^
#|15 |
#|exit 1
