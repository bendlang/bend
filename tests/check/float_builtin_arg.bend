# ported from bend3: unary float math rejects word operands. bend's
# F32.sqrt is a base axiom of the same type, and a strict file may call
# it live, so the check fires on the operand: expected F32, observed
# U32 (bend shows the word as its Word chain).
import Base

law main:
  F32

def main():
  F32.sqrt(4)

#|Error:
#|- expected : F32
#|- observed : U32
#|Location: main
#|10 | def main():
#|11>|   F32.sqrt(4)
#|12 |
#|exit 1
