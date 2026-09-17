# regression witness: a def used as a closure value was a direct
# closure target whenever its last param laid out as one word, so a
# Cmp/Bool/Char argument arrived boxed (term_pak) at a callee reading
# the bare tag word -- every such match took its first arm (C printed
# 257: the LT arm, 40*6 + 17). Direct now means the flat word IS the
# term (a word type or a box, no arms); a packed ADT eta-expands into a
# minted closure whose boxed param is unpacked at the inner call.
import Base
def cu(c: Cmp) -> U32:
  match c:
    case LT{}:
      40
    case EQ{}:
      119
    case GT{}:
      146
def rd11(x: Cmp) -> U32:
  (cu(x) * 6 : U32)
def rd19(f: (Cmp -> U32)) -> U32:
  (f(GT{}) + 17 : U32)
def main() -> IO(Unit):
  IO.print(U32.show(rd19(rd11)))

#|893
