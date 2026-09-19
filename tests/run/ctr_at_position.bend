# A constructor is built at the layout of its position, not at its own
# type and reshaped. The bind's Fail is a static Result at a boxed
# parameter, the list's Done and Fail are static sums at boxed slots,
# and the closure's Some is a tail into a boxed return. The do answers
# 50, the list 137 and the closure 2, so expect 189.

import Base

def g() -> Result<&1, &2, String, Unit>:
  do Result<&1, &2, String, Unit>:
    bc : Bool <- Fail{"x"}
    return Unit{}

def k(r: Result<&1, &2, String, Unit>) -> U32:
  match r:
    case Fail{e}:
      50
    case Done{u}:
      2

def xs() -> List<Result<&1, &2, String, U32>>:
  [Done{7}, Fail{"x"}, Done{30}]

def f(l: List<Result<&1, &2, String, U32>>) -> U32:
  match l:
    case []:
      0
    case h <> t:
      match h:
        case Fail{e}:
          (100 + f(t) : U32)
        case Done{v}:
          (v + f(t) : U32)

def h(m: Maybe<&2, Bool>) -> U32:
  match m:
    case None{}:
      0
    case Some{b}:
      match b:
        case False{}:
          1
        case True{}:
          2

def ap(c: (Bool -> Maybe<&2, Bool>)) -> U32:
  h(c(True{}))

def main() -> IO(Unit):
  IO.print(U32.show(((k(g()) + f(xs()) : U32) + ap(b => Some{b}) : U32)))

#|189
