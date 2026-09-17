# count-down loop shape: the miss branch's predecessor is structurally
# smaller (halt accepts)
# ported from bend3: 0/1+k become Z/S (bend has no number patterns)
type W is Data:
  Z{}
  S{p: W}

law main:
  for k: W
  W

def main(k):
  match k:
    case Z{}:
      Z{}
    case S{k}:
      main(k)

#|\{Z: Z{}; S: (k => main(k))}
