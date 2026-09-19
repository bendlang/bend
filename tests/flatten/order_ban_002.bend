# THE ORDER BAN, locals: the head-binder window is one statement deep,
# so a constructor destructure must sit adjacent to the statement that
# binds its scrutinee -- any local between them takes the head and the
# destructure dies at the ban, like every out-of-order match.
type Nw is Data:
  Zw{}
  Sw{p: Nw}

law f:
  for x: Nw
  Nw

def f(x):
  y = Sw{x}
  z = Zw{}
  Sw{p} = y
  p

law main:
  Nw

def main():
  Zw{}

#|Error:
#|- message  : a match on a parameter or field (this name is a def or a consumed binder: give the value its own def)
#|Location:
#|15 |   z = Zw{}
#|16>|   Sw{p} = y
#|17 |   p
#|exit 1
