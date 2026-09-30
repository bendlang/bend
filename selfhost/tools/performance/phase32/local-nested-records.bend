import Base

type PairBox is Data:
  PairBox{left: U32, right: U32}

type Nest is Data:
  Nest{box: PairBox, stamp: U32}

def pair_box(+x: U32, +y: U32) -> PairBox:
  PairBox{x, y}

# The outer record contains a demanded inner record computation. Its fields
# must not shadow the earlier scalar parameters when unpacked privately.
def nest(+bias: U32, +x: U32) -> Nest:
  Nest{pair_box(x, bias), bias}

def score_box(+a: U32, +b: U32, box: PairBox) -> U32:
  PairBox{x, y} = box
  U32.add(U32.add(a, b), U32.add(x, y))

def score_nest(+a: U32, +b: U32, item: Nest) -> U32:
  Nest{inner, stamp} = item
  U32.add(score_box(a, b, inner), stamp)

def walk(+n: Nat, +acc: U32) -> U32:
  match n:
    case 0n:
      acc
    case 1n+q:
      walk(q, score_nest(3, 5, nest(7, acc)))

def bench(+n: U32, +seed: U32) -> U32:
  walk(U32.to_nat(n), seed)

def main() -> IO(Unit):
  IO.print(U32.show(bench(3, 5)))

#| 71
