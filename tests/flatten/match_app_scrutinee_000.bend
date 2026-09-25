# a lambda-match applied to an (annotated) scrutinee is a banned form:
# the checker rejects it and points at the application
type Nt is Data:
  Zn{}
  Sn{p: Nt}

type R is Data:
  A{}
  B{x: Nt}

law main:
  for n: Nt
  R

def main(n):
  (\{Zn: A{}; Sn: (x => B{x})})({n : Nt})

#|Error:
#|- expected : an annotated term (cannot infer)
#|- observed : \{Zn: A{}; Sn: (x => B{x})}
#|Context:
#|- n : Nt
#|Location: main
#|15 | def main(n):
#|16>|   (\{Zn: A{}; Sn: (x => B{x})})({n : Nt})
#|   |    ^^^^^^^^^^^^^^^^^^^^^^^^^^^
#|17 |
#|exit 1
