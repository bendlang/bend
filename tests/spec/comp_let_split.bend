# comp-splice pin (spec_comp_let_split): bend3's let-bound generic
# template call whose spec split a computed match. bend's ~ law keep
# puts its ~p after a plain clause, which is refused where it is
# written: only leading clauses take ~. (bend3's number switch in the
# predicate respells through U32.is_gt.)
import Base

type B2 is Data:
  T{}
  F{}

type L<-A: Type> is Type:
  C{h: A, t: L<A>}
  N{}

law keep:
  for -A: Type
  for ~p: A -> B2
  for xs: L<A>
  L<A>

def keep(A, p, xs):
  match xs:
    case C{h, t}:
      match p(h):
        case T{}:
          C{h, keep(A, p, t)}
        case F{}:
          keep(A, p, t)
    case N{}:
      N{}

law total:
  for xs: L<U32>
  U32

def total(xs):
  match xs:
    case C{h, t}:
      (h + total(t) : U32)
    case N{}:
      0

law b2:
  for x: U32
  B2

def b2(x):
  match U32.is_gt(x, 1):
    case True{}:
      T{}
    case False{}:
      F{}

law main:
  U32

def main():
  total(keep(U32, x => b2(x), C{1, C{2, C{3, N{}}}}))

#|Error:
#|- expected : a plain clause (only leading clauses take ~)
#|- observed : '~'
#|Location:
#|17 |   for -A: Type
#|18>|   for ~p: A -> B2
#|   |       ^
#|19 |   for xs: L<A>
#|exit 1
