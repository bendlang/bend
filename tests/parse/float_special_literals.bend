# no special float tokens: nan and inf are plain names (unbound here);
# the specials are built by arithmetic -- 1.0 / 0.0 and its kin,
# pinned by run_float_specials
import Base

law main:
  F32

def main():
  nan

#|Error:
#|- expected : a defined name
#|- observed : nan
#|Location: main
#| 9 | def main():
#|10>|   nan
#|11 |
#|exit 1
