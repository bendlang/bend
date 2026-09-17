# red-team pin: a 1-ctor datatype's match flattens to the single case
# (no NotTotal, no default arm)
type W is Data:
  Z{}
  S{p: W}

type One is Data:
  Only{v: W}

law mk:
  for x: W
  One

def mk(x):
  Only{x}

law main:
  for o: One
  W

def main(o):
  match o:
    case Only{v}:
      S{v}

#|\{Only: (v => S{v})}
