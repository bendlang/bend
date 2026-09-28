# A do-Result loop keeps two frames per turn (the generic bind returns a
# boxed value, the loop a flat record). A leaf called from a fork inside a
# bang runs on the lane stack on the device: 1000 turns pass only because
# the device does not hand a leaf off (#930).
import Base

type Tot is Data:
  Tot{a: U32, b: U32, c: U32}

def step(n: U32) -> Result<&2, &2, String, U32>:
  Done{1}

def sums(n: Nat, +acc: U32) -> Result<&2, &2, String, Tot>:
  match n:
    case 0n:
      Done{Tot{acc, acc, acc}}
    case 1n+p:
      do Result<&2, &2, String, Tot>:
        x : U32 <- step(acc)
        sums(p, U32.add(acc, x))

def tot_a(t: Tot) -> U32:
  match t:
    case Tot{a, b, c}: a

def tree(+d: Nat, +n: Nat) -> Result<&2, &2, String, U32>:
  match d:
    case 0n:
      do Result<&2, &2, String, U32>:
        t : Tot <- sums(n, 0)
        return tot_a(t)
    case 1n+p:
      a b = tree(p, n) tree(p, n)
      do Result<&2, &2, String, U32>:
        x : U32 <- a
        y : U32 <- b
        return U32.add(x, y)

def show(r: Result<&2, &2, String, U32>) -> U32:
  match r:
    case Fail{e}: 0
    case Done{v}: v

def main() -> U32:
  show(tree!(2n, 1000n))

#|4000
