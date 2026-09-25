# comp pin (check_list_map_conversion): bend3 minted a comp-lambda spec
# INSIDE a type (List.map over a ~ literal ran during conversion, refl
# closed it). bend's ~ law lmap checks once, f opaque; the pin moves to
# thm's bend3 `=` equation, which bend spells `==`.
import Base

law LL.length:
  for -A: Type
  for xs: List<A>
  Nat

def LL.length(A, xs):
  match xs:
    case Nil{}:
      0n
    case h <> t:
      1n+LL.length(A, t)

law lmap:
  for ~f: U32 -> U32
  for xs: List<U32>
  List<U32>

def lmap(f, xs):
  match xs:
    case Nil{}:
      Nil{}
    case h <> t:
      f(h) <> lmap(f, t)

law thm:
  {LL.length(lmap(x => (x + 1 : U32), [1, 2])) = 2n : Nat}

def thm():
  {=}

law main:
  Nat

def main():
  2n

#|Error:
#|- expected : ':'
#|- observed : '='
#|Location:
#|31 | law thm:
#|32>|   {LL.length(lmap(x => (x + 1 : U32), [1, 2])) = 2n : Nat}
#|   |                                                ^
#|33 |
#|exit 1
