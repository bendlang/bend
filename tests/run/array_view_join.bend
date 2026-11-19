# rebuilding an ANode from its own matched halves: in order they are one
# block again (a view of it, or the block at its root), and a match on the
# result splits it as before; swapped, or halves of two arrays, they are
# copied, and every order of cells reads back the same on every backend
import Base

def setk(+n: Nat, +i: U32, a: Array<U32>) -> Array<U32>:
  match n:
    case 0n:
      a
    case 1n+q:
      setk(q, U32.inc(i), Array.set(U32, a, i, U32.inc(i)))

def iota(+d: Nat) -> Array<U32>:
  setk(Nat.pow(2n, d), 0, Array.new(U32, d, 0))

def hsh(a: Array<U32>, h: U32) -> U32:
  match a:
    case ALeaf{x}:
      U32.add(U32.mul(h, 31), x)
    case ANode{xs, ys}:
      hsh(ys, hsh(xs, h))

def keep(+d: Nat, a: Array<U32>) -> Array<U32>:
  match d:
    case 0n:
      a
    case 1n+p:
      match a:
        case ALeaf{x}:
          ALeaf{x}
        case ANode{xs, ys}:
          ANode{keep(p, xs), keep(p, ys)}

def swap(a: Array<U32>) -> Array<U32>:
  match a:
    case ALeaf{x}:
      ALeaf{x}
    case ANode{xs, ys}:
      ANode{ys, xs}

def low(a: Array<U32>) -> Array<U32>:
  match a:
    case ALeaf{x}:
      ALeaf{x}
    case ANode{xs, ys}:
      xs

def high(a: Array<U32>) -> Array<U32>:
  match a:
    case ALeaf{x}:
      ALeaf{x}
    case ANode{xs, ys}:
      ys

def loop(+n: Nat, a: Array<U32>) -> Array<U32>:
  match n:
    case 0n:
      a
    case 1n+q:
      loop(q, keep(3n, a))

def show(h: U32) -> String:
  U32.show(h)

def main() -> IO(Unit):
  do IO<Unit>:
    Unit <- IO.print(show(hsh(iota(6n), 0)))
    Unit <- IO.print(show(hsh(keep(4n, iota(6n)), 0)))
    Unit <- IO.print(show(hsh(swap(keep(2n, iota(6n))), 0)))
    Unit <- IO.print(show(hsh(ANode{high(iota(6n)), low(iota(6n))}, 0)))
    Unit <- IO.print(show(hsh(low(keep(6n, iota(6n))), 0)))
    IO.print(show(hsh(high(high(loop(100n, iota(10n)))), 0)))

#|2488288288
#|2488288288
#|1666204704
#|1666204704
#|4067041808
#|3943764096
