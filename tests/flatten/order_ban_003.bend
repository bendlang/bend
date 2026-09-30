# THE ORDER BAN, arms: a case's field binder is matchable only while it
# heads the binder window -- a local bound above the nested match takes
# the head, and the field-binder match dies at the ban exactly like an
# out-of-order argument match.
type Nb is Data:
  Zb{}
  Sb{p: Nb}

law f:
  for x: Nb
  Nb

def f(x):
  match x:
    case Zb{}:
      Zb{}
    case Sb{p}:
      t = Zb{}
      match p:
        case Zb{}:
          t
        case Sb{q}:
          q

law main:
  Nb

def main():
  Zb{}

#|SOME PROOFS FAIL
#|Error:
#|- message  : a match on a parameter or field in binder order (this name is bound before one matched earlier, or is a def or a consumed binder: match it first, or give the value its own def)
#|Location:
#|18 |       t = Zb{}
#|19>|       match p:
#|   |             ^
#|20 |         case Zb{}:
#|exit 1
