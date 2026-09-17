# the hand-written twin of comptime_tmpl: incs maps U32.inc by
# recursion. the report diffs the two programs' C (identical up to the
# def name) and times both at 10000000 elements
import Base

def range(n: Nat, +i: U32, acc: List<U32>) -> List<U32>:
  match n:
    case 0n:
      acc
    case 1n+p:
      range(p, (i + 1 : U32), i <> acc)

def incs(xs: List<U32>) -> List<U32>:
  match xs:
    case Nil{}:
      Nil{}
    case h <> t:
      U32.inc(h) <> incs(t)

def total(xs: List<U32>, acc: U32) -> U32:
  match xs:
    case Nil{}:
      acc
    case h <> t:
      total(t, (h + acc : U32))

def main() -> IO(Unit):
  IO.print(U32.show(total(incs(range(U32.to_nat(10000), 0, Nil{})), 0)))

#|50005000
