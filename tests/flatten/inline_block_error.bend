# inline statement blocks are OUT of the language: `{stmt; ..; expr}`
# in a term position is a syntax error -- a brace term is Ann, Eql or
# Rfl and nothing else.
# ported from bend3
import Base

law blk:
  U32

def blk(): {a = 7; a}

law main:
  U32

def main(): blk()

#|Error:
#|- expected : ':'
#|- observed : '='
#|Location:
#| 9 | 
#|10>| def blk(): {a = 7; a}
#|11 |
#|exit 1
