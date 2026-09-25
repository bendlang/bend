# audit 031: constructor arity is checked consistently.
# ported from bend3
type Rr is Data:
  Ra{}

law main:
  Rr

def main(): Ra{Ra{}}

#|Error:
#|- expected : Ra with 0 fields
#|- observed : Ra{Ra{}}
#|Location: main
#| 8 | 
#| 9>| def main(): Ra{Ra{}}
#|   |             ^^^^^^^^
#|10 |
#|exit 1
