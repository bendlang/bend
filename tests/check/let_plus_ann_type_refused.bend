# a family that is Data, annotated as Type: the annotation is the type, so the
# + binder is refused
type Tag<-f: Quant -> Quant> is Data:
  T{}

def main() -> Quant:
  +x = {T{} : {Tag<(a => a)> : Type}};
  &1

#|SOME PROOFS FAIL
#|Error:
#|- expected : Data
#|- observed : Type
#|Location: main
#|6 | def main() -> Quant:
#|7>|   +x = {T{} : {Tag<(a => a)> : Type}};
#|  |   ^^^
#|8 |   &1
#|Note: +x can be used many times, so its type must be Data.
#|exit 1
