# a family whose kind reads its argument: the + binder must not normalize that
# kind before the argument is checked, so a looping argument in a signature
# below the let is refused there, not run
type Tag<-f: Quant -> Quant> is Data:
  T{}

type K<-g: Quant> is Kind(g):
  KK{}

def tag(f: Quant -> Quant) -> Tag<f>:
  T{}

def main() -> Quant:
  -z = tag(a => (+x = gg(); a));
  &1

def gg() -> K<{(x => x(x)) : Quant -> Quant}((x => x(x)))>:
  ?TODO

#|SOME PROOFS FAIL
#|Error:
#|- expected : a function type
#|- observed : Quant
#|Context:
#|- a : Quant
#|- x : Quant
#|Location: main
#|16 |
#|17>| def gg() -> K<{(x => x(x)) : Quant -> Quant}((x => x(x)))>:
#|   |                      ^^^^
#|18 |   ?TODO
#|exit 1
