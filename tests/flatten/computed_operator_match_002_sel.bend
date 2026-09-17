# switch on a computed value with a default row: the rows live in a
# helper def (bend's match takes bare scrutinees and a match heads a
# def body), the computed call rides its application
# ported from bend3: the numeric domain becomes a ctor word (bend has
# no number patterns)
type W is Data:
  Z{}
  S{p: W}

type R is Data:
  R1{}
  RK{k: W}

law dbl:
  for x: W
  W

def dbl(x):
  match x:
    case Z{}:
      Z{}
    case S{p}:
      S{S{dbl(p)}}

law main:
  for y: W
  R

def main(y):
  match y:
    case Z{}:
      R1{}
    case k:
      RK{k}

#|\{Z: R1{}; (y => RK{y})}
