# rewriting a NON-equation goal: the target is a computed Type-family
# (IsEven of a stuck add), stepped by a lemma rewrite until the family
# computes and the IH's evidence fits.
# ported from bend3: add_succ is stated with the eliminated term on the
# right; the arm spends p twice (lemma and IH), so it rebinds a +N
# local (N is Data)
import Base
type Uni is Data:
  U{}
type Emp is Data:

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

law IsEven:
  for n: N
  Type

def IsEven(n):
  match n:
    case Z{}:
      Uni
    case S{Z{}}:
      Emp
    case S{S{p}}:
      IsEven(p)

law even_dbl:
  for n: N
  IsEven(add(n, n))

def even_dbl(n):
  match n:
    case Z{}:
      U{}
    case S{+p}:
      %add_succ(p, p) : IsEven(S{_})
      even_dbl(p)

#|All terms check.
