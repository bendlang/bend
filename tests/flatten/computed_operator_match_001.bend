# computed scrutinee, comparison expression, as bend spells it: a
# worker def matching a Bool parameter, the call in argument position
# ported from bend3: == is no operator in bend (U32.is_eq), literals
# become params (a U32 literal shows as its Word chain)
import Base

law pick:
  for p: U32
  for q: U32
  for z: Bool
  U32

def pick(p, q, z):
  match z:
    case True{}:
      p
    case False{}:
      q

law main:
  for n: U32
  for m: U32
  for p: U32
  for q: U32
  U32

def main(n, m, p, q):
  pick(p, q, U32.is_eq(n, m))

#|n => m => p => q => pick(p, q, Cmp.is_eq(U32.cmp(n, m)))
