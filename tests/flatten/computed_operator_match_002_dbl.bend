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

law main:
  for x: W
  W

def main(x):
  match x:
    case Z{}:
      Z{}
    case S{p}:
      S{S{main(p)}}

law sel:
  for y: W
  R

def sel(y):
  match y:
    case Z{}:
      R1{}
    case k:
      RK{k}

#|\{Z: Z{}; S: (p => S{S{main(p)}})}
