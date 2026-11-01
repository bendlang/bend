# a + let binder still checks its type's kind through a dependent return
# type: tag(f) : Tag<f> and Tag is Type, not Data, so +x is refused
type Tag<-f: Quant -> Quant> is Type:
  T{}

def tag(f: Quant -> Quant) -> Tag<f>:
  T{}

def main() -> Quant:
  +x = tag(q => &1);
  &1

#|SOME PROOFS FAIL
#|Error:
#|- expected : Data
#|- observed : Type
#|Location: main
#| 9 | def main() -> Quant:
#|10>|   +x = tag(q => &1);
#|   |   ^^^
#|11 |   &1
#|Note: +x can be used many times, so its type must be Data.
#|exit 1
