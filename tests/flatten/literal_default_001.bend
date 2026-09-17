# a literal row and a default row over three columns
# ported from bend3: the numeric column becomes a ctor column and the
# arm values become ctor builds (bend has no number patterns)
type W is Data:
  Z{}
  S{p: W}

type R is Data:
  RA{a: W, b: W}
  RN{n: W}

law main:
  for a: W
  for b: W
  for c: W
  R

def main(a, b, c):
  match a, b, c:
    case Z{}, a, b:
      RA{a, b}
    case n, a, b:
      RN{n}

#|\{Z: (b => c => RA{b, c}); (a => b => c => RN{a})}
