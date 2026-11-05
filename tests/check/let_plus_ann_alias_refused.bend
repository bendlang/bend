# as let_plus_ann_type_refused, with the annotation behind an erased let
type Tag<-f: Quant -> Quant> is Data:
  T{}

def main() -> Quant:
  -A = {Tag<(a => a)> : Type};
  +x = {T{} : A};
  &1

#|SOME PROOFS FAIL
#|Error:
#|- expected : Data
#|- observed : Type
#|Context:
#|- A : Type
#|Location: main
#|6 |   -A = {Tag<(a => a)> : Type};
#|7>|   +x = {T{} : A};
#|  |   ^^^
#|8 |   &1
#|Note: +x can be used many times, so its type must be Data.
#|exit 1
