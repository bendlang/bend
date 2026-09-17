# regression witness: the carbonizer's Ctr case walked every field with
# expr, erased ones included, so a live call sitting in an erased field
# (-g1: String holding U32.show(1)) was cut into a let and a minted
# continuation that nothing live ever used; the let survived into a
# call argument, where emit_open admits only flat calls ("an
# under-applied def value: U32.show"), or into a spin body as a
# frame push with no seq ("use of undeclared identifier 'seq'").
# Erased fields are now left as they are: their values are erased.
import Base
type D1 is Data:
  D1a{g0: +Maybe<Nat>, -g1: String, g2: U32}
  D1b{}
def rd7(x: Nat) -> U32:
  (U32.from_nat(x) + 21 : U32)
def rd6(x: Maybe<&2, Nat>) -> U32:
  match x:
    case None{}:
      (1891431819 + 0 : U32)
    case Some{x0}:
      (rd7(x0) - 0 : U32)
def rd5(x: D1) -> U32:
  match x:
    case D1a{x0, x1, x2}:
      ((rd6(x0) - x2) - 8 : U32)
    case D1b{}:
      (2 + 0 : U32)
def us2(+s: D1, +k: U32) -> U32:
  ((rd5(s) * rd5(s)) .^. k : U32)
def cu8(c: Cmp) -> U32:
  match c:
    case LT{}:
      16
    case EQ{}:
      122
    case GT{}:
      159
def rs15() -> U32:
  +sh2 = {D1a{Some{30n}, U32.show(1), 0} : D1}
  v3 = us2(sh2, cu8(U32.cmp(65536, 6)))
  v4 = (rd5(sh2) + v3 : U32)
  +r14 = (((v4 + 0) * 0) .^. 0 : U32)
  ((r14 .&. 3571953678) .|. (r14 .&. U32.not(3571953678)) : U32)
def main() -> IO(Unit):
  do IO<Unit>:
    w0a : Unit <- IO.print(U32.show(rs15()))
    IO.pure(Unit, Unit{})

#|0
