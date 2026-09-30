import Base

type PairBox is Data:
  PairBox{left: U32, right: U32}

type Nest is Data:
  Nest{box: PairBox, stamp: U32}

# These names must normalize to their underlying public/private record types.
def PairAlias() -> Data:
  PairBox

def NestAlias() -> Data:
  Nest

def pair_box(+x: U32, +y: U32) -> PairAlias:
  PairBox{x, y}

def nest(+bias: U32, +x: U32) -> NestAlias:
  Nest{pair_box(x, bias), bias}

def score_box(+a: U32, +b: U32, box: PairAlias) -> U32:
  PairBox{x, y} = box
  U32.add(U32.add(a, b), U32.add(x, y))

def score_nest(+a: U32, +b: U32, item: NestAlias) -> U32:
  Nest{inner, stamp} = item
  U32.add(score_box(a, b, inner), stamp)

# An admitted public Nat worker may return this flat terminal record.
# Alias classification must not turn either zero path into an exposed vector.
def terminal(+n: Nat, +x: U32) -> PairAlias:
  match n:
    case 0n:
      PairBox{x, 7}
    case 1n+q:
      terminal(q, U32.add(x, 1))

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
