# Map.size and Map.values; Set.size, Set.to_list and Set.from_list;
# Array.to_list and Array.map over a written array
import Base

def u32s(xs: List<&2, U32>) -> String:
  List.show(~&2, ~U32, ~(x => U32.show(x)), xs)

def lin(xs: List<U32>) -> String:
  List.show(~&1, ~U32, ~(x => U32.show(x)), xs)

def strs(xs: List<&2, String>) -> String:
  List.show(~&2, ~String, ~(s => s), xs)

def arr() -> Array<U32>:
  a = [0 : U32*4n]
  a[1] <- 5
  a[3] <- 7

def main() -> IO(Unit):
  do IO<Unit>:
    +m : Map<&2, U32> = Map.from_list(&2, U32, [("b", 2), ("a", 1), ("c", 3)])
    IO.print(Nat.show(Map.size(&2, U32, m)))
    IO.print(u32s(Map.values(&2, U32, m)))
    +s : Set() = Set.from_list(["x", "y", "x"])
    IO.print(Nat.show(Set.size(s)))
    IO.print(strs(Set.to_list(s)))
    IO.print(lin(Array.to_list(~U32, arr())))
    IO.print(lin(Array.to_list(~U32, Array.map(~U32, ~U32, ~(x => U32.add(x, 1)), arr()))))

#|3
#|[1, 2, 3]
#|2
#|[x, y]
#|[0, 5, 0, 7]
#|[1, 6, 1, 8]
