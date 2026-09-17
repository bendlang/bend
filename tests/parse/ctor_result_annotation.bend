# audit 033: constructor result annotations are not part of parametric
# datatypes: a ctor row is Name{fields} and nothing follows it.
# ported from bend3
type Bad is Data:
  Mk{} : U32

law main:
  Unit

def main(): Unit{}

#|Error:
#|- expected : 'def', 'type' or 'law'
#|- observed : ':'
#|Location:
#|4 | type Bad is Data:
#|5>|   Mk{} : U32
#|6 |
#|exit 1
