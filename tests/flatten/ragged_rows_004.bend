# first-match order with riding rows: `x Z` above `S{Z} y` wins wherever
# it matches; the rigid row fires only where the default row's own rigid
# column fails
# ported from bend3: numeric columns become ctor columns, literal arm
# values become ctors (bend has no number patterns)
type W is Data:
  Z{}
  S{p: W}

type R is Data:
  R1{}
  R2{}
  R3{}

law main:
  for x: W
  for y: W
  R

def main(x, y):
  match x, y:
    case x, Z{}:
      R1{}
    case S{Z{}}, y:
      R2{}
    case x, y:
      R3{}

#|\{S: \{Z: \{Z: R1{}; (y => R2{})}; (_6 => \{Z: R1{}; (y => R3{})})}; (x => \{Z: R1{}; (y => R3{})})}
