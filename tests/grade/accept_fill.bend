import Base

# omitted leading grades: D<..> fills &1, +D<..> fills &2, +D alone
# fills a grade-only datatype
type Handle<a> is Kind(a):
  MkHandle{n: U32}

law dupl:
  for +xs: +List<U32>
  +List<U32> & +List<U32>

def dupl(xs):
  (xs, xs)

law affine:
  for xs: List<U32>
  List<U32>

def affine(xs):
  xs

law dupm:
  for +m: +Map<Unit>
  +Map<Unit> & +Map<Unit>

def dupm(m):
  (m, m)

law duph:
  for +h: +Handle
  Handle<&2> & Handle<&2>

def duph(h):
  (h, h)

law len:
  for -a : Quant
  for xs : List<a, U32>
  U32

def len(a, xs):
  match xs:
    case Nil{}:
      0
    case h <> t:
      (1 + len(a, t) : U32)

law main.go:
  for p: +List<U32> & +List<U32>
  U32

def main.go(p):
  (a, b) = p
  (len(&2, a) + len(&2, b) : U32)

law main:
  IO(Unit)

def main():
  IO.print(U32.show(main.go(dupl([1, 2]))))

#|4
