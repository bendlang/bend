# Array.map lowers in the C lane to a walk over index ranges of one source
# and one destination: the destination is allocated once, each source cell
# moves out once and each result is written raw into its slot. These rows
# cover a differing layout, a multi-word record with padding, boxed elements,
# and nested arrays on both sides, all through unchanged Array.map calls.
import Base

type Trip is Data:
  Trip{a: U32, b: U32, c: U32}

def rd(r: Array<U32> & U32) -> U32:
  (a, x) = r
  x

def rdn(r: Array<Nat> & Nat) -> Nat:
  (a, x) = r
  x

def main() -> IO(Unit):
  do IO<Unit>:
    one : Array<U32> = Array.map(~U32, ~U32,
      ~(x => U32.add(x, 1)), [41 : U32*1n])
    IO.print(U32.show(rd(Array.get(U32, one, 0))))
    non : Array<U32> = Array.map(~U32, ~U32, ~(x => U32.mul(x, 10)),
      Array.set(U32, Array.set(U32, Array.set(U32, [0 : U32*4n],
        1, 1), 2, 2), 3, 3))
    IO.print(U32.show(rd(Array.get(U32, non, 3))))
    up : Array<U32> = Array.map(~U32, ~U32,
      ~(x => U32.add(x, 1)), [9 : U32*4n])
    IO.print(U32.show(rd(Array.get(U32, up, 3))))
    nat : Array<Nat> = Array.map(~U32, ~Nat,
      ~(x => U32.to_nat(U32.add(x, 2))), [5 : U32*2n])
    IO.print(Nat.show(rdn(Array.get(Nat, nat, 1))))
    trip : Array<Trip> = Array.map(~U32, ~Trip,
      ~(x => Trip{x, 0, 0}), [7 : U32*2n])
    IO.print(U32.show(rd(Array.get(U32, Array.map(~Trip, ~U32,
      ~(t => 0), trip), 0))))
    boxed : Array<U32> = Array.map(~String, ~U32,
      ~(s => 0), ["" : String*4n])
    IO.print(U32.show(rd(Array.get(U32, boxed, 2))))
    rows : Array<Array<U32>> = Array.map(~U32, ~Array<U32>,
      ~(x => [x : U32*2n]), [6 : U32*2n])
    IO.print(U32.show(rd(Array.get(U32, Array.map(~Array<U32>, ~U32,
      ~(r => 1), rows), 1))))

#|42
#|30
#|10
#|7
#|0
#|0
#|1
