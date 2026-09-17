# bend3's gen_mixed miniature: a proof whose equation sides RUN plus
# rewrite-closed lemmas. The counter is gone (no --stats); the proofs
# carry with bend's spelled motives (lemmas state the eliminated term
# on the right), the arm's field feeding lemma, IH and goal rides the
# +a binder (N6 is Data, so its fields inherit +), strict, and the
# literal conversion closes by running
import Base

type N6 is Data:
  Z6{}
  S6{p: N6}

law add6:
  for a: N6
  for b: N6
  N6

def add6(a, b):
  match a:
    case Z6{}:
      b
    case S6{p}:
      S6{add6(p, b)}

law dbl6:
  for a: N6
  N6

def dbl6(a):
  match a:
    case Z6{}:
      Z6{}
    case S6{p}:
      S6{S6{dbl6(p)}}

law add_succ6:
  for  a: N6
  for -b: N6
  {S6{add6(a, b)} == add6(a, S6{b}) : N6}

def add_succ6(a, b):
  match a:
    case Z6{}:
      {==}
    case S6{p}:
      %add_succ6(p, b) : {S6{S6{add6(p, b)}} == S6{_} : N6}
      {==}

law dbl_add6:
  for +a: N6
  {dbl6(a) == add6(a, a) : N6}

def dbl_add6(a):
  match a:
    case Z6{}:
      {==}
    case S6{p}:
      %add_succ6(p, p) : {S6{S6{dbl6(p)}} == S6{_} : N6}
      %dbl_add6(p) : {S6{S6{dbl6(p)}} == S6{S6{_}} : N6}
      {==}

law conv6:
  {dbl6(S6{S6{S6{S6{Z6{}}}}}) == add6(S6{S6{S6{S6{Z6{}}}}}, S6{S6{S6{S6{Z6{}}}}}) : N6}

def conv6():
  {==}

law main:
  N6

def main():
  Z6{}

#|Z6{}
