# a constructor scrutinee under a bare applied match: the application
# is a banned form and the checker rejects it (bend3 reduced it)
type Nt is Data:
  Zn{}
  Sn{p: Nt}

type W is Data:
  Z{}
  S{p: W}

law f:
  for n: Nt
  W

def f(n):
  \{Sn: (k => Z{})}(Sn{n})

law main:
  W

def main():
  Z{}

#|Error:
#|- expected : an annotated term (cannot infer)
#|- observed : \{Sn: (k => Z{})}
#|Context:
#|- n : Nt
#|Location: f
#|15 | def f(n):
#|16>|   \{Sn: (k => Z{})}(Sn{n})
#|   |   ^^^^^^^^^^^^^^^^^
#|17 |
#|exit 1
