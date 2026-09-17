# two fields of ONE constructor matched sequentially
# ported from bend3: a field binder cannot be re-matched inline (bend's
# binder-order law), so the fields route through a helper def whose
# params match freely
type Nt is Data:
  Z{}
  S{p: Nt}

type Duo is Data:
  P{a: Nt, b: Nt}

law go:
  for x: Nt
  for y: Nt
  Nt

def go(x, y):
  match x:
    case Z{}:
      y
    case S{p}:
      match y:
        case Z{}:
          p
        case S{q}:
          q

law main:
  for w: Duo
  Nt

def main(w):
  match w:
    case P{x, y}:
      go(x, y)

#|\{P: (x => y => go(x, y))}
