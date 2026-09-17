# the first-order List kit: length, append, concat, reverse, is_empty,
# head, tail, last, get, set, take, drop, zip, range and replicate,
# each printed through List.show and Maybe.show
import Base

def u32s(xs: List<&2, U32>) -> String:
  List.show(~&2, ~U32, ~(x => U32.show(x)), xs)

def nats(xs: List<&2, Nat>) -> String:
  List.show(~&2, ~Nat, ~(n => Nat.show(n)), xs)

def mu(m: Maybe<&2, U32>) -> String:
  Maybe.show(~&2, ~U32, ~(x => U32.show(x)), m)

def pair(p: U32 & U32) -> String:
  (a, b) = p
  U32.show(a) ++ ":" ++ U32.show(b)

def pairs(xs: List<&1, U32 & U32>) -> String:
  List.show(~&1, ~(U32 & U32), ~pair, xs)

def main() -> IO(Unit):
  do IO<Unit>:
    IO.print(Nat.show(List.length(&2, U32, [1, 2, 3])))
    IO.print(u32s(List.append(&2, U32, [1, 2], [3])))
    IO.print(u32s(List.concat(&2, U32, [[1], [], [2, 3]])))
    IO.print(u32s(List.reverse(&2, U32, [1, 2, 3])))
    IO.print(Bool.show(List.is_empty(&2, U32, [])))
    IO.print(Bool.show(List.is_empty(&2, U32, [1])))
    IO.print(mu(List.head(&2, U32, [7, 8])))
    IO.print(mu(List.head(&2, U32, [])))
    IO.print(u32s(List.tail(&2, U32, [7, 8, 9])))
    IO.print(mu(List.last(&2, U32, [7, 8, 9])))
    IO.print(mu(List.last(&2, U32, [])))
    IO.print(mu(List.get(&2, U32, [10, 20, 30], 1n)))
    IO.print(mu(List.get(&2, U32, [10, 20, 30], 3n)))
    IO.print(u32s(List.set(&2, U32, [10, 20, 30], 2n, 5)))
    IO.print(u32s(List.set(&2, U32, [10, 20, 30], 9n, 5)))
    IO.print(u32s(List.take(&2, U32, [1, 2, 3, 4], 2n)))
    IO.print(u32s(List.take(&2, U32, [1, 2], 5n)))
    IO.print(u32s(List.drop(&2, U32, [1, 2, 3, 4], 2n)))
    IO.print(u32s(List.drop(&2, U32, [1, 2], 5n)))
    IO.print(pairs(List.zip(&2, U32, &2, U32, [1, 2, 3], [4, 5])))
    IO.print(nats(List.range(4n)))
    IO.print(u32s(List.replicate(U32, 3n, 7)))

#|3
#|[1, 2, 3]
#|[1, 2, 3]
#|[3, 2, 1]
#|True
#|False
#|Some(7)
#|None
#|[8, 9]
#|Some(9)
#|None
#|Some(20)
#|None
#|[10, 20, 5]
#|[10, 20, 30]
#|[1, 2]
#|[1, 2]
#|[3, 4]
#|[]
#|[1:4, 2:5]
#|[0, 1, 2, 3]
#|[7, 7, 7]
