# regression witness: a native spin's own references (the spins and
# segments its body calls) were recorded only in the segment being
# emitted when the spin was first built. Here ma2's segment builds the
# rd8 spin (and its inner fold spin) and then dies -- ma2(D0a{}) folds
# at its only call -- while rs's continuation reuses rd8's spin from
# the cache: liveness reached spin_0 but never spin_1, and clang died
# "call to undeclared function 'spin_1'". Each spin now carries its
# refs and the liveness walk follows them.
import Base
def ch(c: Char) -> U32:
  Chr{n} = c
  n
def fold(s: String, +acc: U32) -> U32:
  match s:
    case SNil{}:
      acc
    case SCon{h, t}:
      fold(t, (acc * 31 + ch(h) : U32))
def rd8(x: String) -> U32:
  fold(x, 77)
type D0 is Data:
  D0a{}
  D0b{s: String}
def ma2(+x: D0) -> U32:
  match x:
    case D0a{}:
      1
    case D0b{s}:
      rd8(s)
def rs() -> U32:
  +v1 = ma2(D0a{})
  v11 = U32.show(v1)
  v14 = rd8(v11 ++ "c")
  (v1 + v14 : U32)
def main() -> IO(Unit):
  IO.print(U32.show(rs()))

#|75616
