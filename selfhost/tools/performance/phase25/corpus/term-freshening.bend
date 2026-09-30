# Phase25 compiler term rebuilding analogue
# Shift numeric fields through a term with compact scalar leaves; not capture-avoiding semantic freshening.
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

type Term is Data:
  TVar{id: U32}
  TApp{left: Term, right: Term}
  TLam{id: U32, body: Term}
  TLit{value: U32}

@unsafe
def gen(+n: Nat, +seed: U32) -> Term:
  match n:
    case 0n: TVar{seed}
    case 1n+p: TLam{U32.from_nat(n),TApp{TLit{U32.from_nat(n)},gen(p,seed)}}

@unsafe
def checksum(t: Term) -> U32:
  match t:
    case TVar{x}: x
    case TLit{x}: U32.mul(x,3)
    case TApp{a,b}: U32.add(checksum(a),checksum(b))
    case TLam{x,b}: U32.add(x,checksum(b))

@unsafe
def shift(t: Term, +delta: U32) -> Term:
  match t:
    case TVar{x}: TVar{U32.add(x,delta)}
    case TLit{x}: TLit{x}
    case TApp{a,b}: TApp{shift(a,delta),shift(b,delta)}
    case TLam{x,b}: TLam{U32.add(x,delta),shift(b,delta)}

@unsafe
def bench(+size: U32, +seed: U32) -> U32:
  checksum(shift(gen(U32.to_nat(size),seed),seed))

