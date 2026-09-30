# Phase25 bounded first-order normalization analogue
# Eliminate identity wrappers while rebuilding a shared scalar tree; not full dependent conversion.
import Base

# Runtime inputs and scalar result are shared by both generated-program lanes.
@unsafe
def pick(-A: Type, +b: Bool, yes: Unit -> A, no: Unit -> A) -> A:
  match b:
    case True{}: yes(Unit{})
    case False{}: no(Unit{})

def b2u(b: Bool) -> U32:
  match b:
    case True{}: 1
    case False{}: 0

type Expr is Data:
  Val{value: U32}
  Id{body: Expr}
  Add{left: Expr,right: Expr}

@unsafe
def gen(+n: Nat, +seed: U32) -> Expr:
  match n:
    case 0n: Val{seed}
    case 1n+p: Id{Add{Val{U32.from_nat(n)},gen(p,seed)}}

@unsafe
def eval(e: Expr) -> U32:
  match e:
    case Val{x}: x
    case Id{b}: eval(b)
    case Add{a,b}: U32.add(eval(a),eval(b))

@unsafe
def twice(+e: Expr) -> U32:
  U32.add(eval(e),eval(e))

@unsafe
def bench(+size: U32, +seed: U32) -> U32:
  twice(gen(U32.to_nat(size),seed))

