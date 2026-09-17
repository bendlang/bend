# a DEPENDENT \-match codomain family is still a lambda-match
# application in the type: a banned form, rejected by the checker
type Nt is Data:
  Z{}
  S{p: Nt}

type Bl is Data:
  T{}
  F{}

law main:
  @n: Nt -> @b: Bl -> \{T: {n == n : Nt}; F: Nt}(b)

def main():
  n => \{T: {==}; F: n}

#|Error:
#|- expected : an annotated term (cannot infer)
#|- observed : \{T: {n == n : Nt}; F: Nt}
#|Context:
#|- n : Nt
#|- b : Bl
#|Location: main
#|11 | law main:
#|12>|   @n: Nt -> @b: Bl -> \{T: {n == n : Nt}; F: Nt}(b)
#|13 |
#|exit 1
