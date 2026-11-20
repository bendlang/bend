# as let_plus_kind_arg_loop_refused, at a + lambda binder
type K<-g: Quant> is Kind(g):
  KK{}

def main() -> Quant:
  -z = app(+y => &1);
  &1

def app(h: K<{(x => x(x)) : Quant -> Quant}((x => x(x)))> -> Quant) -> Quant:
  &1

#|SOME PROOFS FAIL
#|Error:
#|- expected : a function type
#|- observed : Quant
#|Context:
#|- x : Quant
#|Location: main
#| 8 |
#| 9>| def app(h: K<{(x => x(x)) : Quant -> Quant}((x => x(x)))> -> Quant) -> Quant:
#|   |                     ^^^^
#|10 |   &1
#|exit 1
