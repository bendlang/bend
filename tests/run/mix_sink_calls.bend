# #2217 x #2175 / #2180 / #2177: U32 lets that sink below a non-tail call
# (only the call after it reads them), in a def whose tail adds its own
# calls (a sum loop, d~acc), in one with a call fixed for the recursion
# (k~fix), and in tree recursions whose returning arms run at the call.
import Base

# queens' shape: b2 and n2 are read only by the sibling call
def walk(+f: Nat, +sib: U32, +x: U32, acc: U32) -> U32:
  match f:
    case 0n:
      U32.add(U32.mul(acc, 3), x)
    case 1n+g:
      +b2 = U32.and(sib, U32.sub(0, sib))
      +n2 = U32.or(x, b2)
      walk(g, U32.sub(sib, b2), U32.add(n2, x),
        walk(g, U32.add(U32.mul(sib, 3), 1), U32.xor(x, sib), acc))

# the same lets in a sum of two self calls
def wsum(+f: Nat, +sib: U32, +x: U32) -> U32:
  match f:
    case 0n:
      U32.and(U32.xor(sib, x), 1023)
    case 1n+g:
      +b2 = U32.and(sib, U32.sub(0, sib))
      +n2 = U32.or(x, b2)
      U32.add(wsum(g, U32.add(U32.mul(sib, 3), 1), U32.xor(x, sib)),
        wsum(g, U32.sub(sib, b2), U32.add(n2, x)))

# a sum whose arm answers 0 (no add of a literal 0) and a three-call sum
def wsum3(+f: Nat, +x: U32) -> U32:
  match f:
    case 0n:
      0
    case 1n+g:
      +a = U32.mul(x, 2654435761)
      +b = U32.xor(a, x)
      +c = U32.add(b, 17)
      U32.add(U32.add(wsum3(g, a), U32.and(c, 7)),
        U32.add(wsum3(g, U32.add(x, 1)), wsum3(g, c)))

def heavy(+n: Nat, +k: U32, acc: U32) -> U32:
  match n:
    case 0n:
      acc
    case 1n+p:
      heavy(p, k, U32.add(U32.mul(acc, 31), U32.xor(k, U32.from_nat(n))))

# heavy(40n, k, 1) is the same at every level: computed once
def fx(+f: Nat, +k: U32, +x: U32) -> U32:
  match f:
    case 0n:
      U32.add(x, heavy(40n, k, 1))
    case 1n+g:
      +b = U32.mul(x, 5)
      +c = U32.add(b, heavy(40n, k, 1))
      +d = U32.xor(x, k)
      U32.add(fx(g, k, c), fx(g, k, U32.add(d, x)))

# a let that must not move: it reads nothing the call does not, but the
# call reads it
def keep(+f: Nat, +x: U32) -> U32:
  match f:
    case 0n:
      x
    case 1n+g:
      +a = U32.add(x, 3)
      U32.add(keep(g, a), keep(g, U32.mul(a, x)))

# forked: a parallel let is left alone
def par(+f: Nat, +sib: U32, +x: U32) -> U32:
  match f:
    case 0n:
      U32.xor(sib, x)
    case 1n+g:
      +b2 = U32.and(sib, U32.sub(0, sib))
      +n2 = U32.or(x, b2)
      l r = par(g, U32.add(U32.mul(sib, 5), 3), x) par(g, U32.sub(sib, b2), n2)
      U32.add(U32.mul(l, 7), r)

def main() -> IO(Unit):
  do IO<Unit>:
    Unit <- IO.print(U32.show(walk(14n, 2654435761, 7, 1)))
    Unit <- IO.print(U32.show(wsum(14n, 2654435761, 7)))
    Unit <- IO.print(U32.show(wsum3(9n, 5)))
    Unit <- IO.print(U32.show(fx(12n, 99, 3)))
    Unit <- IO.print(U32.show(keep(12n, 1)))
    IO.print(U32.show(par(12n, 12345, 678)))

#|2461596685
#|8312102
#|9841
#|3347386475
#|967736050
#|3222225281
