# bend3's term_subst fence, counter layer: the pure case-tree corpus
# rewrote NOTHING and subst_nodes pinned exact zero. The counter is
# gone (no --stats); the corpus itself carries -- the mul commutation
# closes by conversion alone, no rewrite spelled anywhere
import Base

type N8 is Data:
  Z8{}
  S8{p: N8}

law add8:
  for a: N8
  for b: N8
  N8

def add8(a, b):
  match a:
    case Z8{}:
      b
    case S8{p}:
      S8{add8(p, b)}

law mul8:
  for  a: N8
  for +b: N8
  N8

def mul8(a, b):
  match a:
    case Z8{}:
      Z8{}
    case S8{p}:
      add8(b, mul8(p, b))

law m8:
  N8

def m8():
  S8{S8{S8{S8{S8{S8{S8{S8{Z8{}}}}}}}}}

law m9:
  N8

def m9():
  S8{m8()}

law cm:
  {mul8(m8(), m9()) == mul8(m9(), m8()) : N8}

def cm():
  {==}

def N8.text(n: N8) -> String:
  match n:
    case Z8{}:
      "Z8{}"
    case S8{p}:
      "S8{" ++ N8.text(p) ++ "}"

law main:
  IO(Unit)

def main():
  IO.print(N8.text(Z8{}))

#|Z8{}
