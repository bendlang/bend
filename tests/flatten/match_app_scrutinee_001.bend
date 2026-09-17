type N is Data:
  Z{}
  S{p: N}

type P is Data:
  P{a: N, b: N}

# a match application on a let-bound variable is the banned form too:
# the checker rejects the application itself
law main:
  for p: P
  N

def main(p):
  match p:
    case P{a, b}:
      c = a
      (\{Z:b;S: d =>d})(c)

#|Error:
#|- expected : an annotated term (cannot infer)
#|- observed : \{Z: b; S: (d => d)}
#|Context:
#|- a : N
#|- b : N
#|- c : N
#|Location: main
#|17 |       c = a
#|18>|       (\{Z:b;S: d =>d})(c)
#|19 |
#|exit 1
