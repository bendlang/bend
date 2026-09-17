# reg (reg_static_lent_literal): a constant constructor literal is laid
# out in the static region and needs no owner, so passing one to a
# parameter that other callers borrow keeps the parameter borrowed
# (term_static beside the packed rule of facts_scan's site) instead of
# flipping it to owned for every caller. dsum borrows its node: go's d is
# rooted in its own borrowed parameter, and the other argument is the
# literal, with numbers, a nested node and a string inside. The answers
# must agree in every lane, and dsum must read its node in place.
import Base

type D0 is Data:
  D0a{g0: U32}
  D0b{g0: U32, g2: D0}

def dsum(n: D0, +a: U32) -> U32:
  match n:
    case D0a{m}:
      (m + a : U32)
    case D0b{m, r}:
      (m * a + dsum(r, a) : U32)

def len(s: String) -> U32:
  match s:
    case SNil{}:
      0
    case SCon{h, t}:
      (1 + len(t) : U32)

def go(+d: D0, +k: U32) -> U32:
  +a = dsum(d, k)
  +b = dsum(D0b{1, D0b{2, D0a{3}}}, a)
  +c = len("hello")
  (b + c + dsum(d, 2) : U32)

def main() -> IO(Unit):
  do IO<Unit>:
    a : Unit <- IO.print(U32.show(go(D0b{5, D0b{6, D0a{7}}}, 1)))
    IO.print(U32.show(go(D0a{9}, 10)))

#|115
#|95
