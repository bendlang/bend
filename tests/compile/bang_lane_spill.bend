# A bang's root and a fork kid run on a lane's STAK_LEN-word stack on the
# device. A lane that fills it moves its older frames to a heap block under a
# FID_EXIT frame, whose return moves them back, so non-tail recursion under !
# goes as deep on the device as on the host (#1393, #1394). Before, 1023
# List.append frames faulted, and so did a 365-fork spine beside a 3-fork one.
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
      a b = spine(p, (i + 1 : U32)) mix(List.append(&2, U32, gen(800n, i, []), gen(64n, i, [])), i)
      (a + b : U32)

def two(+n: Nat) -> U32:
  a b = spine(n, 0) spine(3n, 0)
  (a + b : U32)

def main() -> IO(Unit):
  do IO<Unit>:
    IO.print(U32.show(deep!(5000n)))
    IO.print(U32.show(two!(365n)))

#|1543298507
#|2063974529
