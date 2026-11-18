# a generic def that is not flat, unfolded over a literal list: its other
# list argument is computed, bound once and then shared by the arm that
# ends the literal. The elements are boxes, so the list's nodes and its
# elements' must both be known as shared where the caller reads them.
import Base

type KL is Data:
  KNil{}
  KCon{k: U32, t: KL}

def kl(n: Nat, +x: U32, acc: KL) -> KL:
  match n:
    case 0n:
      acc
    case 1n+p:
      kl(p, U32.inc(x), KCon{x, acc})

def kl_sum(c: KL, acc: U32) -> U32:
  match c:
    case KNil{}:
      acc
    case KCon{k, t}:
      kl_sum(t, U32.add(acc, k))

def kls(n: Nat, +x: U32, acc: List<&2, KL>) -> List<&2, KL>:
  match n:
    case 0n:
      acc
    case 1n+p:
      kls(p, U32.inc(x), Con{kl(3n, x, KNil{}), acc})

def sums(xs: List<&2, KL>, acc: U32) -> U32:
  match xs:
    case Nil{}:
      acc
    case Con{h, t}:
      sums(t, kl_sum(h, U32.mul(acc, 3)))

# not flat; ys is used twice where xs ends
def glue(-A: Data, xs: List<&2, A>, +ys: List<&2, A>) -> List<&2, A>:
  match xs:
    case Nil{}:
      List.append(&2, A, ys, ys)
    case Con{h, t}:
      Con{h, glue(A, t, ys)}

def n() -> U32:
  kl_sum(kl(500n, 1, KNil{}), 0)

# not flat either; the arm for 0n holds ys twice, with no call that
# would say so
def twice(-A: Data, n: Nat, +ys: List<&2, A>) -> List<&2, List<&2, A>>:
  match n:
    case 0n:
      Con{ys, Con{ys, Nil{}}}
    case 1n+p:
      Con{ys, twice(A, p, ys)}

def sums2(xs: List<&2, List<&2, KL>>, acc: U32) -> U32:
  match xs:
    case Nil{}:
      acc
    case Con{h, t}:
      sums2(t, sums(h, U32.inc(acc)))

def user.end(-A: Data, w: A, x: U32) -> U32:
  x

# the caller's own type parameter has glue's name and place, and is not
# the element type
def user(-A: Data, w: A, +x: U32) -> U32:
  g = glue(KL, [KCon{1, KNil{}}, KNil{}, KCon{2, KCon{3, KNil{}}}],
    kls(U32.to_nat(U32.add(U32.and(x, 3), 2)), x, Nil{}))
  t = twice(KL, 1n, kls(U32.to_nat(U32.add(U32.and(x, 3), 2)), x,
    Nil{}))
  user.end(A, w, sums2(t, sums(g, x)))

def round(+x: U32) -> U32:
  user(U32, 5, x)

def main() -> IO(Unit):
  IO.print(U32.show(round(n())) ++ " " ++ U32.show(round(n())))

#|1149271657 1149271657
