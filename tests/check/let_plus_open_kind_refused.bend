# a family whose kind is a parameter: q is not known to be Data, so the + binder
# falls through to the full check, which refuses it
type K<-g: Quant> is Kind(g):
  KK{}

def ky(g: Quant) -> K<g>:
  KK{}

def f(q: Quant) -> Quant:
  +x = ky(q);
  &1

def main() -> Quant:
  f(&1)

#|SOME PROOFS FAIL
#|Error:
#|- expected : Data
#|- observed : Kind(q)
#|Context:
#|- q : Quant
#|Location: f
#| 9 | def f(q: Quant) -> Quant:
#|10>|   +x = ky(q);
#|   |   ^^^
#|11 |   &1
#|Note: +x can be used many times, so its type must be Data.
#|exit 1
