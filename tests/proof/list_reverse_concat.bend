# FLAGSHIP: list algebra over the Base accumulator reverse, generic
# over element types -- the reverse.go/append lemma tower up to
# reverse(append a b) = append(reverse b, reverse a) and the reverse
# involution, plus map-over-append at a concrete named function.
# ported from bend3: List.concat/reverse_go become base LL.append/
# LL.reverse.go; every rewrite carries an explicit motive, and each
# lemma is stated with the term its callers eliminate on the right
# (cat_nil, rgo_cat and rev_cat_go flip); the element type is Data so
# List<&2, A> is Data and the double spends ride plain + binders; map
# rides a named inc (a function is never +), so the tower checks strict;
# check instantiates rev_rev at U32
import Base

law LL.append:
  for -A : Data
  for xs : List<&2, A>
  for ys : List<&2, A>
  List<&2, A>

def LL.append(A, xs, ys):
  match xs:
    case Nil{}:
      ys
    case h <> t:
      h <> LL.append(A, t, ys)

law LL.reverse.go:
  for -A  : Data
  for xs  : List<&2, A>
  for acc : List<&2, A>
  List<&2, A>

def LL.reverse.go(A, xs, acc):
  match xs:
    case Nil{}:
      acc
    case h <> t:
      LL.reverse.go(A, t, h <> acc)

law LL.reverse:
  for -A : Data
  for xs : List<&2, A>
  List<&2, A>

def LL.reverse(A, xs):
  LL.reverse.go(A, xs, Nil{})

law cat_nil:
  for -A : Data
  for xs : List<&2, A>
  {xs == LL.append(A, xs, Nil{}) : List<&2, A>}

def cat_nil(A, xs):
  match xs:
    case Nil{}:
      {==}
    case h <> t:
      %cat_nil(A, t) : {h <> t == h <> _ : List<&2, A>}
      {==}

law cat_assoc:
  for -A: Data
  for  a: List<&2, A>
  for  b: List<&2, A>
  for  c: List<&2, A>
  {LL.append(A, LL.append(A, a, b), c) == LL.append(A, a, LL.append(A, b, c)) : List<&2, A>}

def cat_assoc(A, a, b, c):
  match a:
    case Nil{}:
      {==}
    case h <> t:
      %cat_assoc(A, t, b, c) : {h <> LL.append(A, LL.append(A, t, b), c) == h <> _ : List<&2, A>}
      {==}

law rgo_cat:
  for -A   : Data
  for +xs  : List<&2, A>
  for +acc : List<&2, A>
  {LL.append(A, LL.reverse.go(A, xs, Nil{}), acc) == LL.reverse.go(A, xs, acc) : List<&2, A>}

def rgo_cat(A, xs, acc):
  match xs:
    case Nil{}:
      {==}
    case h <> t:
      %rgo_cat(A, t, h <> acc) : {LL.append(A, LL.reverse.go(A, t, [h]), acc) == _ : List<&2, A>}
      %rgo_cat(A, t, [h]) : {LL.append(A, _, acc) == LL.append(A, LL.reverse.go(A, t, Nil{}), h <> acc) : List<&2, A>}
      %cat_assoc(A, LL.reverse.go(A, t, Nil{}), [h], acc) : {LL.append(A, LL.append(A, LL.reverse.go(A, t, Nil{}), [h]), acc) == _ : List<&2, A>}
      {==}

law rev_cat_go:
  for -A: Data
  for +a: List<&2, A>
  for +b: List<&2, A>
  {LL.append(A, LL.reverse.go(A, b, Nil{}), LL.reverse.go(A, a, Nil{})) == LL.reverse.go(A, LL.append(A, a, b), Nil{}) : List<&2, A>}

def rev_cat_go(A, a, b):
  match a:
    case Nil{}:
      rgo_cat(A, b, Nil{})
    case h <> t:
      %rgo_cat(A, LL.append(A, t, b), [h]) : {LL.append(A, LL.reverse.go(A, b, Nil{}), LL.reverse.go(A, t, [h])) == _ : List<&2, A>}
      %rev_cat_go(A, t, b) : {LL.append(A, LL.reverse.go(A, b, Nil{}), LL.reverse.go(A, t, [h])) == LL.append(A, _, [h]) : List<&2, A>}
      %rgo_cat(A, t, [h]) : {LL.append(A, LL.reverse.go(A, b, Nil{}), _) == LL.append(A, LL.append(A, LL.reverse.go(A, b, Nil{}), LL.reverse.go(A, t, Nil{})), [h]) : List<&2, A>}
      %cat_assoc(A, LL.reverse.go(A, b, Nil{}), LL.reverse.go(A, t, Nil{}), [h]) : {_ == LL.append(A, LL.append(A, LL.reverse.go(A, b, Nil{}), LL.reverse.go(A, t, Nil{})), [h]) : List<&2, A>}
      {==}

law rev_cat:
  for -A: Data
  for +a: List<&2, A>
  for +b: List<&2, A>
  {LL.append(A, LL.reverse(A, b), LL.reverse(A, a)) == LL.reverse(A, LL.append(A, a, b)) : List<&2, A>}

def rev_cat(A, a, b):
  rev_cat_go(A, a, b)

law rev_rev:
  for -A: Data
  for +a: List<&2, A>
  {LL.reverse(A, LL.reverse(A, a)) == a : List<&2, A>}

def rev_rev(A, a):
  match a:
    case Nil{}:
      {==}
    case h <> t:
      %rgo_cat(A, t, [h]) : {LL.reverse.go(A, _, Nil{}) == h <> t : List<&2, A>}
      %rev_cat_go(A, LL.reverse.go(A, t, Nil{}), [h]) : {_ == h <> t : List<&2, A>}
      %rev_rev(A, t) : {LL.append(A, [h], LL.reverse.go(A, LL.reverse.go(A, t, Nil{}), Nil{})) == h <> _ : List<&2, A>}
      {==}

law inc:
  for x: U32
  U32

def inc(x):
  U32.add(x, 1)

law map_inc:
  for xs: List<&2, U32>
  List<&2, U32>

def map_inc(xs):
  match xs:
    case Nil{}:
      Nil{}
    case h <> t:
      inc(h) <> map_inc(t)

law map_cat:
  for +a: List<&2, U32>
  for  b: List<&2, U32>
  {map_inc(LL.append(U32, a, b)) == LL.append(U32, map_inc(a), map_inc(b)) : List<&2, U32>}

def map_cat(a, b):
  match a:
    case Nil{}:
      {==}
    case h <> t:
      %map_cat(t, b) : {inc(h) <> map_inc(LL.append(U32, t, b)) == inc(h) <> _ : List<&2, U32>}
      {==}

law check:
  {LL.reverse(U32, LL.reverse(U32, [1, 2, 3])) == [1, 2, 3] : List<&2, U32>}

def check(): rev_rev(U32, [1, 2, 3])

law main:
  {LL.reverse(U32, LL.reverse(U32, [1, 2, 3])) == [1, 2, 3] : List<&2, U32>}

def main(): check()

#|{==}
