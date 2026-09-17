# bend3's checker work pin (interactions under a flat budget) loses its
# counter (no --stats) and keeps its content: the same Nat kit, the
# add_zero ladder and the mul(8,9) == mul(9,8) conversion all close on
# bend's checker (mul's contracted operand rides a + binder)
import Base

type N7 is Data:
  Z7{}
  S7{p: N7}

law add7:
  for a: N7
  for b: N7
  N7

def add7(a, b):
  match a:
    case Z7{}:
      b
    case S7{p}:
      S7{add7(p, b)}

law mul7:
  for  a: N7
  for +b: N7
  N7

def mul7(a, b):
  match a:
    case Z7{}:
      Z7{}
    case S7{p}:
      add7(b, mul7(p, b))

law add_zero7:
  for a: N7
  {add7(a, Z7{}) == a : N7}

def add_zero7(a):
  match a:
    case Z7{}:
      {==}
    case S7{p}:
      %add_zero7(p) : {S7{add7(p, Z7{})} == S7{_} : N7}
      {==}

law n8:
  N7

def n8():
  S7{S7{S7{S7{S7{S7{S7{S7{Z7{}}}}}}}}}

law n9:
  N7

def n9():
  S7{n8()}

law cm:
  {mul7(n8(), n9()) == mul7(n9(), n8()) : N7}

def cm():
  {==}

def N7.text(n: N7) -> String:
  match n:
    case Z7{}:
      "Z7{}"
    case S7{p}:
      "S7{" ++ N7.text(p) ++ "}"

law main:
  IO(Unit)

def main():
  IO.print(N7.text(Z7{}))

#|Z7{}
