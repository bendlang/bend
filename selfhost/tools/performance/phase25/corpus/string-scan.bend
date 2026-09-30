# Phase25 lexer codepoint-walk analogue
# Classify every character and accumulate codepoints; no full tokenizer semantics claimed.
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
def scan(s: String, acc: U32) -> U32:
  match s:
    case SNil{}: acc
    case SCon{+h,t}: scan(t,U32.add(acc,U32.add(Char.to_u32(h),b2u(Char.is_digit(h)))))

@unsafe
def spin(+n: Nat, +s: String, acc: U32) -> U32:
  match n:
    case 0n: acc
    case 1n+p: spin(p,s,scan(s,acc))

@unsafe
def bench(+size: U32, +seed: U32) -> U32:
  spin(U32.to_nat(size),text(seed),seed)

