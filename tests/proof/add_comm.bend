# theorems: add_comm over a local Nat -- two lemmas (add_zero, add_succ),
# stacked rewrites, and the recursive call as the induction hypothesis.
# ported from bend3: rewrites carry explicit motives; add_succ is stated
# with the term each rewrite eliminates on the right; b's double spend
# rides a +b binder (N is Data)

import Base
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

law add_zero:
  for a: N
  {add(a, Z{}) == a : N}

def add_zero(a):
  match a:
    case Z{}:
      {==}
    case S{p}:
      %add_zero(p) : {S{add(p, Z{})} == S{_} : N}
      {==}

law add_succ:
  for  a: N
  for -b: N
  {S{add(a, b)} == add(a, S{b}) : N}

def add_succ(a, b):
  match a:
    case Z{}:
      {==}
    case S{p}:
      %add_succ(p, b) : {S{S{add(p, b)}} == S{_} : N}
      {==}

law add_comm:
  for  a: N
  for +b: N
  {add(a, b) == add(b, a) : N}

def add_comm(a, b):
  match a:
    case Z{}:
      %add_zero(b) : {_ == add(b, Z{}) : N}
      {==}
    case S{p}:
      %add_succ(b, p) : {S{add(p, b)} == _ : N}
      %add_comm(p, b) : {S{add(p, b)} == S{_} : N}
      {==}

law main:
  {add(S{S{Z{}}}, S{Z{}}) == add(S{Z{}}, S{S{Z{}}}) : N}

def main(): add_comm(S{S{Z{}}}, S{Z{}})

#|{==}
