# a def called once whose return layout is a box (pick returns F(b), one
# layout per index) does not fuse into a caller typed at one index (get
# returns Duo): it jumps, and its return converts through the cut. Fused,
# the C lane died laying count's U32 into Duo's arms
import Base

type Duo is Data:
  DuoV{a: U32, b: U32}

def F(b: Bool) -> Type:
  match b:
    case True{}:
      U32
    case False{}:
      Duo

def keep(-A: Type, x: A) -> A:
  x

def count(n: Nat) -> U32:
  match n:
    case 0n:
      7
    case 1n+p:
      keep(U32, count(p))

def make(n: Nat) -> Duo:
  match n:
    case 0n:
      DuoV{1, 2}
    case 1n+p:
      keep(Duo, make(p))

def pick(n: Nat, b: Bool) -> F(b):
  match b:
    case True{}:
      count(n)
    case False{}:
      make(n)

def get(n: Nat) -> Duo:
  pick(n, False{})

def sum(p: Duo) -> U32:
  match p:
    case DuoV{a, b}:
      U32.add(a, b)

def main() -> U32:
  U32.add(sum(get(2n)), count(1n))

#|10
