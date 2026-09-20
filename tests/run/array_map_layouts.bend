# Array.map keeps its Type generic signature and its tree definition. These rows
# cover a leaf, a wide array, a different output layout and an element that owns
# a box.
import Base

def u32s(xs: List<U32>) -> String:
  List.show(~&1, ~U32, ~(x => U32.show(x)), xs)

def strs(xs: List<String>) -> String:
  List.show(~&1, ~String, ~(s => s), xs)

def nats(xs: List<Nat>) -> String:
  List.show(~&1, ~Nat, ~(n => Nat.show(n)), xs)

def rows(xs: List<Array<U32>>) -> String:
  List.show(~&1, ~Array<U32>, ~(r => u32s(Array.to_list(~U32, r))), xs)

def rowsum.fold(xs: List<U32>, acc: U32) -> U32:
  List.foldl(~&1, ~U32, ~U32, ~(a => x => U32.add(a, x)), xs, acc)

def rowsum(r: Array<U32>) -> U32:
  rowsum.fold(Array.to_list(~U32, r), 0)

def main() -> IO(Unit):
  do IO<Unit>:
    mine : Array<U32> = Array.set(U32, [1 : U32*2n], 1, 3)
    rows_out : Array<Array<U32>> = Array.map(~U32, ~Array<U32>,
      ~(x => [x : U32*2n]), mine)
    IO.print(rows(Array.to_list(~Array<U32>, rows_out)))
    rows_in : Array<Array<U32>> = Array.map(~U32, ~Array<U32>,
      ~(x => [x : U32*2n]), Array.set(U32, [1 : U32*2n], 1, 3))
    IO.print(u32s(Array.to_list(~U32,
      Array.map(~Array<U32>, ~U32, ~(r => rowsum(r)), rows_in))))
    one : Array<U32> = Array.map(~U32, ~U32,
      ~(x => U32.add(x, 1)), [0 : U32*1n])
    IO.print(u32s(Array.to_list(~U32, one)))
    wide : Array<U32> = Array.map(~U32, ~U32,
      ~(x => U32.add(x, 1)), [0 : U32*16n])
    IO.print(u32s(Array.to_list(~U32, wide)))
    boxed : Array<U32> = Array.map(~String, ~U32,
      ~(s => U32.from_nat(String.length(s))), ["" : String*4n])
    IO.print(u32s(Array.to_list(~U32, boxed)))
    wide_out : Array<Nat> = Array.map(~U32, ~Nat,
      ~(x => U32.to_nat(U32.add(x, 2))), [0 : U32*4n])
    IO.print(nats(Array.to_list(~Nat, wide_out)))
    strs_out : Array<String> = Array.map(~U32, ~String,
      ~(x => U32.show(x)), [7 : U32*2n])
    IO.print(strs(Array.to_list(~String, strs_out)))

#|[[1, 1], [3, 3]]
#|[2, 6]
#|[1]
#|[1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]
#|[0, 0, 0, 0]
#|[2, 2, 2, 2]
#|[7, 7]
