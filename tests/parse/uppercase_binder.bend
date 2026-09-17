# uppercase binders: lambda binders may be uppercase (Y => ...), and a
# type-parameter style bind (-A: Type) binds like any var.
# ported from bend3
type Vq2 is Data:
  Qv2{}

law id2:
  for -A: Type
  for  x: A
  A

def id2(A, x):
  x

law bump:
  for f: Vq2 -> Vq2
  for x: Vq2
  Vq2

def bump(f, x):
  f(x)

law main:
  Vq2

def main():
  bump(Y => Y, id2(Vq2, Qv2{}))

#|Qv2{}
