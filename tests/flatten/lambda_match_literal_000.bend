# a \-match codomain family is a lambda-match APPLICATION in the type:
# a banned form, rejected by the checker (spell the family as a def)
type Bl is Data:
  T{}
  F{}

type W is Data:
  Z{}
  S{p: W}

law main:
  @b: Bl -> \{T: W; F: W}(b)

def main():
  \{T: S{Z{}}; F: Z{}}

#|Error:
#|- expected : an annotated term (cannot infer)
#|- observed : \{T: W; F: W}
#|Context:
#|- b : Bl
#|Location: main
#|11 | law main:
#|12>|   @b: Bl -> \{T: W; F: W}(b)
#|13 |
#|exit 1
