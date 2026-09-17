# def-form: a computed match on the def's own recursive call; the rows
# live in a helper def (bend's idiom)
# ported from bend3: numerics become ctor words
type Nt is Data:
  Zn{}
  Sn{p: Nt}

type W is Data:
  Z{}
  S{p: W}

law main:
  for r: W
  W

def main(r):
  match r:
    case Z{}:
      S{Z{}}
    case k:
      Z{}

#|\{Z: S{Z{}}; (r => Z{})}
