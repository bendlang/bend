# the typed-let statement is not grammar: a bend let is `x = v`, and a
# typed value spells the Ann brace, `x = {v : T}`.
# ported from bend3: bend3 ratified `x : T = v`; bend pins the refusal
import Base

law main:
  U32

def main():
  z : U32 = 30
  z

#|Error:
#|- expected : 'def', 'type' or 'law'
#|- observed : ':'
#|Location:
#| 9 | def main():
#|10>|   z : U32 = 30
#|11 |   z
#|exit 1
