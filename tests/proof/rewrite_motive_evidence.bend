# J over its evidence: the motive of %h@e binds the endpoint _ and the
# equation h, so it can prove sym twice is the identity, a fact about
# the evidence itself, not just its endpoints
type N is Data:
  Z{}
  S{p: N}

law sym:
  for -a: N
  for -b: N
  for  e: {a == b : N}
  {b == a : N}

def sym(a, b, e):
  %e : {_ == a : N}
  {==}

law sym_sym:
  for -a: N
  for -b: N
  for  e: {a == b : N}
  {sym(b, a, sym(a, b, e)) == e : {a == b : N}}

def sym_sym(a, b, e):
  %h@e : {sym(_, a, sym(a, _, h)) == h : {a == _ : N}}
  {==}

law main:
  N

def main(): Z{}

#|Z{}
