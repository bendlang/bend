# audit 024: reserved names cannot be used as constructor fields.
# ported from bend3
type Kk8 is Data:
  Mk8{Type: Kk8}

law main:
  Kk8

def main(): Mk8{}

#|Error:
#|- expected : a name (got the keyword 'Type')
#|- observed : ':'
#|Location:
#|3 | type Kk8 is Data:
#|4>|   Mk8{Type: Kk8}
#|5 |
#|exit 1
