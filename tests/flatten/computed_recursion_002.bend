# a SELF scrutinee: a computed match on the def's own recursive call;
# the literal-plus-default rows live in a helper def (bend's idiom)
# ported from bend3: numerics become ctor words
type Nt is Data:
  Zn{}
  Sn{p: Nt}

type W is Data:
  Z{}
  S{p: W}

law sel:
  for r: W
  W

def sel(r):
  match r:
    case S{Z{}}:
      Z{}
    case k:
      S{Z{}}

law main:
  for n: Nt
  W

def main(n):
  match n:
    case Zn{}:
      S{Z{}}
    case Sn{p}:
      sel(main(p))

#|\{Zn: S{Z{}}; Sn: (p => sel(main(p)))}
