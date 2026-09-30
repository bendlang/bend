# THE ORDER BAN, past a local: the match on b closes a, and a local
# statement sits between it and the match on a, which is still an order
# error (the local alone, order_ban_003, is another)
type Nw is Data:
  Zw{}
  Sw{p: Nw}

law f:
  for a: Nw
  for b: Nw
  Nw

def f(a, b):
  match b:
    case Zw{}:
      a
    case Sw{k}:
      t = Zw{}
      match a:
        case Zw{}:
          t
        case Sw{j}:
          j

law main:
  Nw

def main():
  Zw{}

#|SOME PROOFS FAIL
#|Error:
#|- message  : a match on a parameter or field in binder order (this name is bound before one matched earlier, or is a def or a consumed binder: match it first, or give the value its own def)
#|Location:
#|18 |       t = Zw{}
#|19>|       match a:
#|   |             ^
#|20 |         case Zw{}:
#|exit 1
