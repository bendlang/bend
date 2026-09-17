# bend3 pinned that a LET-BOUND call result matches like the computed
# call itself; bend bans both spellings alike: matching a local binder
# is the same banned form, so the match moves to a worker def
type Nt is Data:
  Zn{}
  Sn{p: Nt}

type Bl is Data:
  T{}
  F{}

type W is Data:
  Z{}
  S{p: W}

law main:
  for n: Nt
  Bl

def main(n):
  match n:
    case Zn{}:
      T{}
    case Sn{p}:
      F{}

law step:
  for w: Bl
  W

def step(w):
  match w:
    case T{}:
      S{Z{}}
    case F{}:
      Z{}

#|\{Zn: T{}; Sn: (p => F{})}
