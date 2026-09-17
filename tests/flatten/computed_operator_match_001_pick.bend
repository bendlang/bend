# computed scrutinee, comparison expression, as bend spells it: a
# worker def matching a Bool parameter, the call in argument position
# ported from bend3: == is no operator in bend (U32.is_eq), literals
# become params (a U32 literal shows as its Word chain)
import Base

law main:
  for p: U32
  for q: U32
  for z: Bool
  U32

def main(p, q, z):
  match z:
    case True{}:
      p
    case False{}:
      q

#|p => q => \{True: p; False: q}
