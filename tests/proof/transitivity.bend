# transitivity is a one-rewrite lemma at ANY carrier (a Type parameter), and
# chains close by conversion on machine words.
# ported from bend3: <A> generics become an erased Type parameter; infix
# arithmetic becomes U32.add/U32.sub; the motive is explicit
import Base

law trans:
  for -A : Type
  for -a : A
  for -b : A
  for -c : A
  for e1 : {a == b : A}
  for e2 : {b == c : A}
  {a == c : A}

def trans(A, a, b, c, e1, e2):
  %e2 : {a == _ : A}
  e1

law main:
  {5 == U32.sub(10, 5) : U32}

def main(): trans(U32, 5, U32.add(2, 3), U32.sub(10, 5), {==}, {==})

#|{==}
