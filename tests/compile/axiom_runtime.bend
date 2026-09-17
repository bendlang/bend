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

#|Error:
#|- expected : a filled definition (an unfilled law is a dead claim: live code cannot use it)
#|- observed : magic
#|Location: main
#|13 | def main():
#|14>|   magic
#|15 |
#|exit 1
