# a dependent proof over a multiply-mentioned Nat: match instantiates the
# motive at the matched value; call sites just pass it.
# ported from bend3: --eval q becomes a main that returns q()
type N is Data:
  Z{}
  S{p: N}

law add:
  for a: N
  for b: N
  N

def add(a, b):
  match a:
    case Z{}:
      b
    case S{p}:
      S{add(p, b)}

law add0:
  for n: N
  {add(n, Z{}) == n : N}

def add0(n):
  match n:
    case Z{}:
      {==}
    case S{p}:
      %add0(p) : {S{add(p, Z{})} == S{_} : N}
      {==}

law q:
  {add(S{Z{}}, Z{}) == S{Z{}} : N}

def q(): add0(S{Z{}})

law main:
  {add(S{Z{}}, Z{}) == S{Z{}} : N}

def main(): q()

#|{==}
