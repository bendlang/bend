import Base

# a fresh def types itself inline: a Bind telescope and a "->" return
# type, one form for the type and the body. a bare Bind name is a
# Quant, as in a datatype head; - erases; + licenses many uses.
def ident(-A: Type, x: A) -> A:
  x

def dupl(+xs: +List<U32>) -> +List<U32> & +List<U32>:
  (xs, xs)

def len(a, xs: List<a, U32>) -> U32:
  match xs:
    case Nil{}:
      0
    case h <> t:
      (1 + len(a, t) : U32)

def add(a: U32, b: U32) -> U32:
  (a + b : U32)

def main.go(p: +List<U32> & +List<U32>) -> U32:
  (xs, ys) = p
  add(len(&2, xs), len(&2, ys))

def main() -> IO(Unit):
  IO.print(U32.show(main.go(dupl(ident(+List<U32>, [1, 2, 3])))))

#|6
