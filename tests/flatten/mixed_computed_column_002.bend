# a pattern column beside a value column: every row binds the value as
# a var, riding it through the match
# ported from bend3: the computed x+1 becomes the ctor build S{x} bound
# through the var column (bend's match takes bare scrutinees)
type Nt is Data:
  Zn{}
  Sn{p: Nt}

type W is Data:
  Z{}
  S{p: W}

law main:
  for n: Nt
  for x: W
  W

def main(n, x):
  match n, x:
    case Zn{}, x:
      S{x}
    case Sn{p}, x:
      main(p, S{x})

#|\{Zn: (x => S{x}); Sn: (p => x => main(p, S{x}))}
