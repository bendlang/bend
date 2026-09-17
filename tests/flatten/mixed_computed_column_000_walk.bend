# a pattern column beside a computed value, in both orders; bend's
# match takes bare scrutinees, so the value rides a var column (main)
# or feeds a helper's pattern column (sel)
# ported from bend3: numerics become ctor columns (W), x+1 becomes the
# ctor build WS{x}, x%2 becomes a structural parity main, literal arm
# values become ctors
type Nat is Data:
  Z{}
  S{p: Nat}

type W is Data:
  WZ{}
  WS{p: W}

type R is Data:
  R1{}
  R2{}
  R3{}
  R4{}

law par:
  for x: W
  W

def par(x):
  match x:
    case WZ{}:
      WZ{}
    case WS{p}:
      match p:
        case WZ{}:
          WS{WZ{}}
        case WS{q}:
          par(q)

law main:
  for n: Nat
  for x: W
  W

def main(n, x):
  match n, x:
    case Z{}, x:
      WS{x}
    case S{p}, x:
      main(p, WS{x})

law sel:
  for k: W
  for n: Nat
  R

def sel(k, n):
  match k, n:
    case WZ{}, Z{}:
      R1{}
    case WZ{}, S{p}:
      R2{}
    case k, Z{}:
      R3{}
    case k, S{p}:
      R4{}

#|\{Z: (x => WS{x}); S: (p => x => main(p, WS{x}))}
