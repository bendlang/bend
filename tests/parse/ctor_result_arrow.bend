# audit: constructor result arrows are rejected instead of being treated
# as fields.
# ported from bend3
type Dd is Data:
  Cc{} : U32 -> Dd

law main:
  Unit

def main(): Unit{}

#|Error:
#|- expected : 'def', 'type' or 'law'
#|- observed : ':'
#|Location:
#|4 | type Dd is Data:
#|5>|   Cc{} : U32 -> Dd
#|  |        ^
#|6 |
#|exit 1
