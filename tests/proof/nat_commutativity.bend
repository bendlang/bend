# add_comm over a local Nat: m is spent twice -- once inside add_succ's
# live position, once by the IH.
# ported from bend3: the double spend bend3 allowed on any Data binder
# is bend's +m binder over the Data-kinded local N; add_succ is
# stated with the term each rewrite eliminates on the RIGHT, since a
# bend rewrite folds the right endpoint back into the left

import Base
type N is Data:
  Z{}
  S{p: N}

law add:
  for n: N
  for m: N
  N

def add(n, m):
  match n:
    case Z{}:
      m
    case S{k}:
      S{add(k, m)}

law add_zero:
  for n: N
  {add(n, Z{}) == n : N}

def add_zero(n):
  match n:
    case Z{}:
      {==}
    case S{k}:
      %add_zero(k) : {S{add(k, Z{})} == S{_} : N}; {==}

law add_succ:
  for  n: N
  for -m: N
  {S{add(n, m)} == add(n, S{m}) : N}

def add_succ(n, m):
  match n:
    case Z{}:
      {==}
    case S{k}:
      %add_succ(k, m) : {S{S{add(k, m)}} == S{_} : N}; {==}

law add_comm:
  for  n: N
  for +m: N
  {add(n, m) == add(m, n) : N}

def add_comm(n, m):
  match n:
    case Z{}:
      %add_zero(m) : {_ == add(m, Z{}) : N}; {==}
    case S{k}:
      %add_succ(m, k) : {S{add(k, m)} == _ : N}
      %add_comm(k, m) : {S{add(k, m)} == S{_} : N}
      {==}

law main:
  {add(S{S{Z{}}}, S{Z{}}) == add(S{Z{}}, S{S{Z{}}}) : N}

def main(): add_comm(S{S{Z{}}}, S{Z{}})

#|{==}
