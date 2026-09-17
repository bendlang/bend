# per-branch arity via a \-match codomain family: a lambda-match
# application in the type is a banned form, rejected by the checker
type Bl is Data:
  T{}
  F{}

type W is Data:
  Z{}
  S{p: W}

law main:
  @b: Bl -> \{T: @x: W -> W; F: W}(b)

def main():
  \{
    T: (x => \{Z: S{Z{}}; S: (p => p)}(x));
    F: Z{}
  }

#|Error:
#|- expected : an annotated term (cannot infer)
#|- observed : \{T: @x:W -> W; F: W}
#|Context:
#|- b : Bl
#|Location: main
#|11 | law main:
#|12>|   @b: Bl -> \{T: @x: W -> W; F: W}(b)
#|13 |
#|exit 1
