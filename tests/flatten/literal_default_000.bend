# a literal row and a default row
# ported from bend3: the numeric column becomes a ctor column and the
# literal results become ctors (bend has no number patterns)
type W is Data:
  Z{}
  S{p: W}

type R is Data:
  R1{}
  R2{}

law main:
  for a: W
  R

def main(a):
  match a:
    case Z{}:
      R1{}
    case n:
      R2{}

#|\{Z: R1{}; (a => R2{})}
