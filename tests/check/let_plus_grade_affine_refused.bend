# a family whose kind reads its leading quantity, at the literal &1: its kind
# is Type, so a + binder at it is refused with main's message
import Base

type Tag<-f: Quant -> Quant> is Data:
  T{}

def tag(f: Quant -> Quant) -> List<&1, Tag<f>>:
  []

def main() -> Quant:
  +x = tag(a => a);
  &1

#|SOME PROOFS FAIL
#|Error:
#|- expected : Data
#|- observed : Type
#|Location: main
#|11 | def main() -> Quant:
#|12>|   +x = tag(a => a);
#|   |   ^^^
#|13 |   &1
#|Note: +x can be used many times, so its type must be Data.
#|exit 1
