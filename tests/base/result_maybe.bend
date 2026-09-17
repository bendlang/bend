# Result/Maybe plumbing: a do-block over Result, bind stops at Fail,
# or/map serve defaults
# ported from bend3: Result.or/map and Maybe.some/none/or become local
# ror/rmap and Maybe ctors with Maybe.default; do-binds carry the bend
# type annotation
import Base

law bu:
  for b: Bool
  U32

def bu(b):
  match b:
    case False{}:
      0
    case True{}:
      1

law ror:
  for d: U32
  for r: Result<&2, &2, U32, U32>
  U32

def ror(d, r):
  match r:
    case Fail{e}:
      d
    case Done{v}:
      v

law rmap:
  for f: U32 -> U32
  for r: Result<&2, &2, U32, U32>
  Result<&2, &2, U32, U32>

def rmap(f, r):
  match r:
    case Fail{e}:
      Fail{e}
    case Done{v}:
      Done{f(v)}

law resdo:
  Result<&2, &2, U32, U32>

def resdo():
  do Result<&2, &2, U32, U32>:
    x : U32 <- Result.pure(&2, &2, U32, U32, 3)
    y : U32 <- Result.pure(&2, &2, U32, U32, 4)
    return U32.add(U32.mul(x, 10), y)

law failing:
  Result<&2, &2, U32, U32>

def failing():
  Fail{7}

law resfail:
  Result<&2, &2, U32, U32>

def resfail():
  do Result<&2, &2, U32, U32>:
    x : U32 <- failing()
    y : U32 <- Result.pure(&2, &2, U32, U32, 4)
    return U32.add(U32.mul(x, 10), y)

law main.out:
  U32

def main.out():
  b0 = bu(U32.is_eq(ror(99, resdo()), 34))
  b1 = bu(U32.is_eq(ror(99, resfail()), 99))
  b2 = bu(U32.is_eq(ror(9, rmap(x => U32.add(x, 1), resdo())), 35))
  b3 = bu(U32.is_eq(Maybe.default(&2, U32, {Some{5} : Maybe<&2, U32>}, 8), 5))
  b4 = bu(U32.is_eq(Maybe.default(&2, U32, {None{} : Maybe<&2, U32>}, 8), 8))
  U32.add(U32.add(U32.add(U32.add(b0, b1), b2), b3), b4)

law main:
  IO(Unit)

def main():
  IO.print(U32.show(main.out()))

#|5
