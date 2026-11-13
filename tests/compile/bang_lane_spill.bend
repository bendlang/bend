# A bang's root and a fork kid run on a lane's STAK_LEN-word stack on the
# device. A call that may leave no room for a frame moves the lane's stack to
# a heap block under an exit frame, and a return into that frame moves whole
# defs back, about half a stack, so non-tail recursion under ! goes past the
# stack on the device (#1393, #1394). Before, 1023 List.append frames
# faulted, and so did a 365-fork spine beside a 3-fork one. walk's spills come
# at its second call, while it holds words from its first, and give them back.
# down leaves loop a few words under the top, so the first h it calls spills;
# the return gives back half a stack and the loop runs low from then on, where
# giving back the whole stack spilled on every h (6,000 times). halves appends
# the two halves of each split, another shape that faulted at 2,046 elements.
# bang_lane_spill_wide.bend has a wide def.
import Base

def gen(n: Nat, +k: U32, acc: List<&2, U32>) -> List<&2, U32>:
  match n:
    case 0n:
      acc
    case 1n+p:
      gen(p, (k + 1 : U32), k <> acc)

def mix(xs: List<&2, U32>, +acc: U32) -> U32:
  match xs:
    case Nil{}:
      acc
    case Con{h, t}:
      mix(t, ((acc * 31 : U32) + h : U32))

def deep(+n: Nat) -> U32:
  mix(List.append(&2, U32, gen(n, 0, []), [7]), 0)

def spine(n: Nat, +i: U32) -> U32:
  match n:
    case 0n:
      0
    case 1n+p:
      a b = spine(p, (i + 1 : U32))
        mix(List.append(&2, U32, gen(800n, i, []), gen(64n, i, [])), i)
      (a + b : U32)

type Q is Data:
  Q{a: U32, b: U32, c: U32, d: U32, e: U32}

def leaf(+k: U32) -> Q:
  Q{k, (k * 3 : U32), (k * 5 : U32), (k * 7 : U32), (k + 9 : U32)}

def sum(q: Q) -> U32:
  match q:
    case Q{a, b, c, d, e}:
      (((((a + b : U32) * 3 : U32) + c : U32)
        + ((d + e : U32) * 5 : U32) : U32) * 7 : U32)

def walk(n: Nat, +k: U32) -> U32:
  match n:
    case 0n:
      k
    case 1n+p:
      q b = leaf(k) walk(p, (k + 1 : U32))
      (((sum(q) + b : U32) * 31 : U32) + k : U32)

def two(+n: Nat) -> U32:
  a b = spine(n, 0) spine(3n, 0)
  (a + b : U32)

def pair(+n: Nat) -> U32:
  a b = walk(n, 1) walk(3n, 0)
  (a + b : U32)

def h(n: Nat, +a: U32) -> U32:
  match n:
    case 0n:
      a
    case 1n+p:
      y = h(p, a)
      ((y * 31 : U32) + 7 : U32)

def loop(n: Nat, +acc: U32) -> U32:
  match n:
    case 0n:
      acc
    case 1n+p:
      x = h(2n, acc)
      y = h(2n, x)
      loop(p, (y + 1 : U32))

def down(d: Nat, +n: Nat) -> U32:
  match d:
    case 0n:
      loop(n, 0)
    case 1n+p:
      x = down(p, n)
      (x + 1 : U32)

def halves(+f: Nat, +n: Nat, +k: U32) -> List<&2, U32>:
  match f:
    case 0n:
      []
    case 1n+g:
      match n:
        case 0n:
          []
        case 1n+p:
          match p:
            case 0n:
              [k]
            case 1n+q:
              +m = Nat.div(n, 2n)
              lo hi = halves(g, m, k)
                halves(g, Nat.sub(n, m), (k + 1 : U32))
              List.append(&2, U32, lo, hi)

def main() -> IO(Unit):
  do IO<Unit>:
    IO.print(U32.show(deep!(5000n)))
    IO.print(U32.show(two!(365n)))
    IO.print(U32.show(pair!(600n)))
    IO.print(U32.show(down!(2036n, 3000n)))
    IO.print(U32.show(mix(halves!(64n, 4096n, 0), 0)))

#|1543298507
#|2063974529
#|1878402805
#|2841842604
#|3759572992
