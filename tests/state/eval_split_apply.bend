# compound-scrutinee ladder, complete: splitting n computes the cut
# away in both arms (wob's scrutinee add(n, Z{}) rides its own def
# and reduces per arm)
# ported from bend3: no pre-split rewrite -- a bend match heads a def
# body, so the split comes first, and both arms then close by {==}
type MN is Data:
  Z{}
  S{p: MN}

law add:
  for a: MN
  for b: MN
  MN

def add(a, b):
  match a:
    case Z{}:
      b
    case S{p}:
      S{add(p, b)}

law wob:
  for n: MN
  MN

law wob.go:
  for m: MN
  MN

def wob.go(m):
  match m:
    case Z{}:
      Z{}
    case S{p}:
      S{p}

def wob(n):
  wob.go(add(n, Z{}))

law wob_id:
  for n: MN
  {wob(n) == add(n, Z{}) : MN}

def wob_id(n):
  match n:
    case Z{}:
      {==}
    case S{p}:
      {==}

law main:
  @n: MN -> {wob(n) == add(n, Z{}) : MN}

def main():
  n => wob_id(n)

#|n => wob_id(n)
