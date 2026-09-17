# regression (AUDIT 6a): a malformed import head gets the import
# diagnostic, not the parser's 'expected def/type/assert' pointing at
# the i
import Wat
law main:
  Nat

def main():
  1n

#|Error:
#|- expected : an import ('import Base', or 'import <path> as <Name>')
#|- observed : 'import Wat'
#|Location:
#|3 | # the i
#|4>| import Wat
#|5 | law main:
#|exit 1
