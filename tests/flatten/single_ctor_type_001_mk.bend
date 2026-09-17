# red-team pin: a 1-ctor datatype's match flattens to the single case
# (no NotTotal, no default arm)
type W is Data:
  Z{}
  S{p: W}

type One is Data:
  Only{v: W}

law main:
  for x: W
  One

def main(x):
  Only{x}

#|x => Only{x}
