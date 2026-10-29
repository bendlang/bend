# a meet is the minimum, so Kind(a) fits Kind(b) when every leaf of a's
# meets fits some leaf of b's: order and grouping never matter. A leaf may
# match the first leaf (first), only the last (last, rev), a repeat (rep),
# across groupings (nest), or past &2, the meet's identity (lit)

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
