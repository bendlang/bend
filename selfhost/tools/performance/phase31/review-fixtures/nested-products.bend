import Base

type Marker is Data:
  Marker{}

def marker_value(+bias: U32, m: Marker) -> U32:
  Marker{} = m
  U32.inc(bias)

def pair_total(r: U32 & U32) -> U32:
  (x, y) = r
  U32.add(x, y)

def nested_total(+bias: U32, r: (U32 & U32) & (U32 & U32)) -> U32:
  (left, right) = r
  U32.add(bias, U32.add(pair_total(left), pair_total(right)))

def walk(+n: Nat, +acc: U32) -> U32:
  match n:
    case 0n:
      acc
    case 1n+q:
      walk(q, nested_total(marker_value(3, Marker{}), ((acc, 1), (2, 3))))

def bench(+n: U32, +seed: U32) -> U32:
  walk(U32.to_nat(n), seed)

def main() -> IO(Unit):
  IO.print(U32.show(bench(3, 5)))

#| 35
