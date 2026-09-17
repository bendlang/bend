# a word match's miss arm reuses the scrutinee through its rebinding
# default binder in bend3; the ctor respell binds the predecessor
# ported from bend3: 0/1+k become Z/S (bend has no number patterns)
type W is Data:
  Z{}
  S{p: W}

law main:
  for i: W
  W

def main(i):
  match i:
    case Z{}:
      Z{}
    case S{k}:
      k

#|\{Z: Z{}; S: (k => k)}
