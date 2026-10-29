# a meet is the minimum, so its operands' order and grouping never change
# a kind: each side splits its meets into leaves, and each leaf of one
# side finds a leaf of the other. the search stops at its first match
# (#1942): the issue's chains searched every leaf after the answer,
# O(n^3) wnf steps. a leaf may match the first leaf (first), only the
# last (last, rev), a repeat (rep), across groupings (nest), or past a
# &2, the meet's identity (lit)

def swap(q: Quant, r: Quant, X: Kind(q <&> r)) -> Kind(r <&> q):
  X

def rep(q: Quant, r: Quant, X: Kind(q <&> r <&> q <&> r)) -> Kind(r <&> q <&> r <&> q):
  X

def first(q: Quant, r: Quant, X: Kind(q)) -> Kind(q <&> r):
  X

def last(q: Quant, r: Quant, s: Quant, X: Kind(s)) -> Kind(q <&> r <&> s):
  X

def rev(q: Quant, r: Quant, s: Quant, X: Kind(q <&> r <&> s)) -> Kind(s <&> r <&> q):
  X

def nest(q: Quant, r: Quant, s: Quant, X: Kind(q <&> (r <&> s))) -> Kind((s <&> q) <&> r):
  X

def lit(q: Quant, r: Quant, X: Kind((q <&> &2) <&> r)) -> Kind(r <&> q):
  X

#|ALL PROOFS CHECK
#|Use --verdict for mathematical validity.
