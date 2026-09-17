# audit: datatype field types are checked before definitions use them.
# ported from bend3
type Bad9 is Data:
  Mk9{x: Missing9}

law main:
  Bad9

def main(): Mk9{}

#|Error:
#|- expected : a defined name
#|- observed : Missing9
#|Location: Mk9
#|3 | type Bad9 is Data:
#|4>|   Mk9{x: Missing9}
#|5 |
#|exit 1
