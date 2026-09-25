# a match-lambda applied to a constructor scrutinee is a banned form:
# the checker rejects the application itself.
# ported from bend3
type Nx5 is Data:
  Zx5{}
  Sx5{p: Nx5}

type Rx5 is Data:
  Ax5{x: Nx5}
  Bx5{y: Nx5}

law main:
  Rx5

def main(): (\{Zx5: Bx5{Zx5{}}; Sx5: x => Ax5{x}})(Zx5{})

#|Error:
#|- expected : an annotated term (cannot infer)
#|- observed : \{Zx5: Bx5{Zx5{}}; Sx5: (x => Ax5{x})}
#|Location: main
#|14 | 
#|15>| def main(): (\{Zx5: Bx5{Zx5{}}; Sx5: x => Ax5{x}})(Zx5{})
#|   |              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
#|16 |
#|exit 1
