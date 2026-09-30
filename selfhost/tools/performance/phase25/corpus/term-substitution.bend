# Phase25 compiler first-order term substitution analogue
# Four-constructor term traversal; preserve binder shadows and rebuild only this simplified domain.
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
def subst(t: Term, +key: U32, +value: U32) -> Term:
  match t:
    case TVar{+x}: pick(Term,U32.is_eq(x,key),u => TLit{value},u => TVar{x})
    case TLit{x}: TLit{x}
    case TApp{a,b}: TApp{subst(a,key,value),subst(b,key,value)}
    case TLam{+x,+b}: pick(Term,U32.is_eq(x,key),u => TLam{x,b},u => TLam{x,subst(b,key,value)})

@unsafe
def bench(+size: U32, +seed: U32) -> U32:
  checksum(subst(gen(U32.to_nat(size),seed),seed,U32.add(seed,17)))

