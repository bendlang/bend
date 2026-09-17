# bend3's census warned on a bodiless assert from an imported file;
# bend's law is file-blind: an unfilled assert is dead wherever it
# was stated, so its live use refuses at validation (the corpus is
# single-file by the runner's law, so the assert stands in-file; an
# import cannot change the verdict)
import Base

law EVIL_ADD_HOM:
  {0 == 1 : U32}

law use:
  {0 == 1 : U32}

def use():
  EVIL_ADD_HOM

law main:
  U32

def main():
  0

#|Error:
#|- expected : a filled definition (an unfilled law is a dead claim: live code cannot use it)
#|- observed : EVIL_ADD_HOM
#|Location: use
#|14 | def use():
#|15>|   EVIL_ADD_HOM
#|16 |
#|exit 1
