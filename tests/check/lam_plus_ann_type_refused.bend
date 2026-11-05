# as let_plus_ann_type_refused, at a + lambda binder
type Tag<-f: Quant -> Quant> is Data:
  T{}

def app(g: {Tag<(a => a)> : Type} -> Quant) -> Quant:
  &1

def main() -> Quant:
  app(+x => &1)

#|SOME PROOFS FAIL
#|Error:
#|- expected : Data
#|- observed : Type
#|Location: main
#| 8 | def main() -> Quant:
#| 9>|   app(+x => &1)
#|   |       ^^^
#|10 |
#|Note: +x can be used many times, so its type must be Data.
#|exit 1
