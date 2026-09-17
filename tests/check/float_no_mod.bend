# the dotted-both-sides .%. is no operator: F32.mod is % under : F32,
# and after a full term the parser expects a term boundary, not a dot
import Base

law main:
  F32

def main():
  5.5 .%. 2.0

#|Error:
#|- expected : 'def', 'type' or 'law'
#|- observed : '.'
#|Location:
#| 8 | def main():
#| 9>|   5.5 .%. 2.0
#|10 |
#|exit 1
