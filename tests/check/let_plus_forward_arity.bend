# too many arguments in a signature below the let: the + binder must not read the
# kind through them, so this reports the arity, as the full check does
type Tag<-f: Quant -> Quant> is Data:
  T{}

def tag(f: Quant -> Quant) -> Tag<f>:
  T{}

def main() -> Quant:
  -z = tag(a => (+x = g(); a));
  &1

def g() -> Tag<(a => a), (a => a)>:
  ?TODO

#|SOME PROOFS FAIL
#|Error:
#|- expected : Tag with 1 parameter
#|- observed : Tag<a => a, a => a>
#|Context:
#|- a : Quant
#|Location: main
#|12 |
#|13>| def g() -> Tag<(a => a), (a => a)>:
#|   |            ^^^^^^^^^^^^
#|14 |   ?TODO
#|exit 1
