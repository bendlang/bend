# a + lambda binder at a family whose signature says Type is still refused
type TyTag<-f: Quant -> Quant> is Type:
  U{}

def app(g: TyTag<(a => a)> -> Quant) -> Quant:
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
