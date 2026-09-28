# A ! whose forks form a right spine (one leaf per level, the rest of the
# spine as the other kid) unrolls whole in the device's grow pass, which ends
# only when its group is full or nothing grew, as the host's row_grow does.
# Before, a grow kernel stopped after 128 turns, so the work pass ran the
# rest of the spine on one lane in seq mode, four stack words a level, and
# 768 levels overran the lane's 2048 words with the ERR_DEEP line; the cores
# had no cap, so only a Metal or CUDA run pins this.
import Base

def row(n: Nat, +y: U32, acc: List<&2, U32>) -> List<&2, U32>:
  match n:
    case 0n:
      acc
    case 1n++p:
      row(p, y, U32.add(y, U32.from_nat(p)) <> acc)

def spine(n: Nat, +w: U32) -> List<List<&2, U32>>:
  match n:
    case 0n:
      Nil{}
    case 1n++p:
      a b = row(U32.to_nat(w), U32.from_nat(p), Nil{}) spine(p, w)
      a <> b

def total(xs: List<List<&2, U32>>, acc: U32) -> U32:
  match xs:
    case Nil{}:
      acc
    case x <> rest:
      total(rest, U32.add(acc, U32.from_nat(List.length(&2, U32, x))))

def main() -> IO(Unit):
  IO.print(U32.show(total(spine!(1000n, 96), 0)))

#|96000
