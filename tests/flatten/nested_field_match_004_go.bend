# two fields of ONE constructor matched sequentially
# ported from bend3: a field binder cannot be re-matched inline (bend's
# binder-order law), so the fields route through a helper def whose
# params match freely
type Nt is Data:
  Z{}
  S{p: Nt}

type Duo is Data:
  P{a: Nt, b: Nt}

law main:
  for x: Nt
  for y: Nt
  Nt

def main(x, y):
  match x:
    case Z{}:
      y
    case S{p}:
      match y:
        case Z{}:
          p
        case S{q}:
          q

#|\{Z: (y => y); S: (p => \{Z: p; S: (q => q)})}
