# a device turn must see what the host wrote under the bump, and the host
# what the device wrote: bump (host, no fork) rebuilds every node of a
# device-built tree in freed slots, the host allocates a fresh tree beside
# it, and the device mirrors and folds both, over three ! turns. A lane that
# keeps the corpus in device memory and copies only part of it gets a stale
# page wrong here. sum is order-sensitive.
import Base

type Tr is Data:
  Lf{v: U32}
  Nd{l: Tr, r: Tr}

def gen(+n: Nat, +x: U32) -> Tr:
  match n:
    case 0n:
      Lf{x}
    case 1n+p:
      l r = gen(p, U32.shl(x)) gen(p, U32.inc(U32.shl(x)))
      Nd{l, r}

def sum(t: Tr) -> U32:
  match t:
    case Lf{v}:
      v
    case Nd{l, r}:
      a b = sum(l) sum(r)
      U32.add(U32.xor(U32.mul(a, 2654435761), b), 7)

# host, one call after the other: no fork
def bump(t: Tr) -> Tr:
  match t:
    case Lf{v}:
      Lf{U32.inc(v)}
    case Nd{l, r}:
      x = bump(l)
      y = bump(r)
      Nd{x, y}

# device: mirror the tree (every node rewritten on the device)
def flip(t: Tr) -> Tr:
  match t:
    case Lf{v}:
      Lf{v}
    case Nd{l, r}:
      a b = flip(l) flip(r)
      Nd{b, a}

def main() -> IO(Unit):
  t0 = gen!(16n, 1)
  t1 = bump(t0)
  t2 = flip!(t1)
  t3 = bump(t2)
  h  = gen(10n, 3)
  t4 = flip!(Nd{t3, h})
  t5 = bump(t4)
  s  = sum!(t5)
  IO.print(U32.show(s))

#|691345207
