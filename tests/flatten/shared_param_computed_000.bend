# shared &-param scrutinee: `match *n` on a share-bound param is a
# COMPUTED match, split into an aux at check time; main's residual keeps
# the stuck application (the share round-trip Own(&n) cancels in print)
type Nat is Data:
  Z{}
  S{p: Nat}

law main:
  for n: Nat
  Nat

def main(n):
  match n:
    case Z{}:
      Z{}
    case S{p}:
      p

#|\{Z: Z{}; S: (p => p)}
