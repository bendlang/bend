# the template twin of comptime_hand: List.map with ~U32.inc compiles
# to the hand-written loop (its C is comptime_hand's up to the name)
import Base

def range(n: Nat, +i: U32, acc: List<U32>) -> List<U32>:
  match n:
    case 0n:
      acc
    case 1n+p:
      range(p, (i + 1 : U32), i <> acc)

def total(xs: List<U32>, acc: U32) -> U32:
  match xs:
    case Nil{}:
      acc
    case h <> t:
      total(t, (h + acc : U32))

def main() -> IO(Unit):
  xs = range(U32.to_nat(10000), 0, Nil{})
  IO.print(U32.show(total(List.map(~U32, ~U32, ~U32.inc, xs), 0)))

#|50005000
