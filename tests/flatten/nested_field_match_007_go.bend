# nested field match whose inner arms use the SIBLING field: t stays
# bound across the elimination of h
# ported from bend3: a field binder cannot be re-matched inline (bend's
# binder-order law), so the fields route through a helper def
type Nt is Data:
  Z{}
  S{p: Nt}

type Tree is Data:
  Leaf{}
  Node{h: Nt, t: Nt}

law main:
  for h: Nt
  for t: Nt
  Nt

def main(h, t):
  match h:
    case Z{}:
      t
    case S{p}:
      S{t}

#|\{Z: (t => t); S: (p => t => S{t})}
