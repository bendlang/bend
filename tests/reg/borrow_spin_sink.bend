# regression witness: a fused reader (Xs.sum, a loop compiled to a spin)
# asked to lend by one site (F reads xs after it) and called at another
# where the list dies (G). Both borrow: G's body sinks the list right
# after its last spin call. Before, G's last use made Xs.sum an owner and
# F shared the list. In the C, F and G are spin functions (flat) with no
# term_keep, each ending in a term_sink of xs after its second spin call,
# and the spins of Xs.sum and Xs.mix read through term_peek.
import Base

type Xs is Data:
  X0{}
  X1{v: U32, rest: Xs}

def Xs.build(n: Nat, +acc: U32) -> Xs:
  match n:
    case 0n:
      X0{}
    case 1n+p:
      X1{acc, Xs.build(p, (acc + 1 : U32))}

def Xs.sum(xs: Xs, +acc: U32) -> U32:
  match xs:
    case X0{}:
      acc
    case X1{v, rest}:
      Xs.sum(rest, (acc + v : U32))

def Xs.mix(xs: Xs, +acc: U32) -> U32:
  match xs:
    case X0{}:
      acc
    case X1{v, rest}:
      Xs.mix(rest, (acc * 3 + v : U32))

def F(+xs: Xs) -> U32:
  +s = Xs.sum(xs, 0)
  (s + Xs.mix(xs, 0) : U32)

def G(+xs: Xs) -> U32:
  +m = Xs.mix(xs, 0)
  (m * Xs.sum(xs, 0) : U32)

def main() -> IO(Unit):
  IO.print(U32.show((F(Xs.build(10n, 1)) + G(Xs.build(4n, 1)) : U32)))

#|44916
