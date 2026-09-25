# THE ORDER BAN, top level: match scrutinees must follow the argument
# order -- an out-of-order scrutinee column is a surface-language
# error, never a partial fusion.
# ported from bend3
type Ny is Data:
  Zy{}
  Sy{p: Ny}

law f:
  for a: Ny
  for b: Ny
  Ny

def f(a, b):
  match b, a:
    case Zy{}, y:
      y
    case Sy{k}, y:
      k

law main:
  Ny

def main():
  Zy{}

#|Error:
#|- message  : a match on a parameter or field (this name is a def or a consumed binder: give the value its own def)
#|Location:
#|14 | def f(a, b):
#|15>|   match b, a:
#|   |            ^
#|16 |     case Zy{}, y:
#|exit 1
