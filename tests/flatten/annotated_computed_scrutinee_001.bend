# a lambda-match applied to an annotated constructor scrutinee is a
# banned form: the checker rejects the application itself
type Nt is Data:
  Zn{}
  Sn{p: Nt}

type Bl is Data:
  T{}
  F{}

law main:
  for n: Nt
  Bl

def main(n):
  \{Sn: (k => T{}); Zn: F{}}({Sn{n} : Nt})

#|Error:
#|- expected : an annotated term (cannot infer)
#|- observed : \{Sn: (k => T{}); Zn: F{}}
#|Context:
#|- n : Nt
#|Location: main
#|15 | def main(n):
#|16>|   \{Sn: (k => T{}); Zn: F{}}({Sn{n} : Nt})
#|17 |
#|exit 1
