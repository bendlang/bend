# Phase25 renamed has_name mechanism; worker preserves current helper body
# String equality, early hit and full miss; no claim to benchmark full declaration lookup.
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

@unsafe
def names(+n: Nat) -> List<&2,String>:
  match n:
    case 0n: Nil{}
    case 1n+p: Con{"alpha", names(p)}

@unsafe
def member(+xs: List<&2,String>, +key: String) -> Bool:
  match xs:
    case Nil{}: False{}
    case Con{h,t}: pick(Bool, String.eq(h,key), u => True{}, u => member(t,key))

@unsafe
def bench(+size: U32, +seed: U32) -> U32:
  key = pick(String,U32.is_even(seed),u => "alpha",u => "absent")
  U32.add(seed,b2u(member(names(U32.to_nat(size)),key)))

