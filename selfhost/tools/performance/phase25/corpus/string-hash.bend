# Phase25 renamed exact index_hash recurrence
# FNV-1a codepoint hash from core/index.bend; runtime seed and ASCII/Unicode data.
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
def text(seed: U32) -> String:
  pick(String,U32.is_even(seed),u => "alpha.beta_0123456789",u => "λ雪𝄞.beta_0123456789")

@unsafe
def hash(+name: String, +acc: U32) -> U32:
  match name:
    case SNil{}: acc
    case SCon{h,rest}: hash(rest,U32.mul(U32.xor(acc,Char.to_u32(h)),16777619))

@unsafe
def spin(+n: Nat, +s: String, acc: U32) -> U32:
  match n:
    case 0n: acc
    case 1n+p: spin(p,s,hash(s,acc))

@unsafe
def bench(+size: U32, +seed: U32) -> U32:
  spin(U32.to_nat(size),text(seed),seed)

