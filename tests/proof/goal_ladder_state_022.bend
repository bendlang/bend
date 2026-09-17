# goal ladder, tower state 3 (after cat_assoc): reassociation -- the
# residual closes by conversion.
# ported from bend3: the ladder rides the ported bend development, so
# the pinned page is bend's own goal at the same proof state
import Base

law LL.append:
  for -A: Data
  for xs: List<&2, A>
  for ys: List<&2, A>
  List<&2, A>

def LL.append(A, xs, ys):
  match xs:
    case Nil{}:
      ys
    case h <> t:
      h <> LL.append(A, t, ys)

law LL.reverse.go:
  for -A: Data
  for xs: List<&2, A>
  for acc: List<&2, A>
  List<&2, A>

def LL.reverse.go(A, xs, acc):
  match xs:
    case Nil{}:
      acc
    case h <> t:
      LL.reverse.go(A, t, h <> acc)

law cat_assoc:
  for -A: Data
  for a: List<&2, A>
  for b: List<&2, A>
  for c: List<&2, A>
  {LL.append(A, LL.append(A, a, b), c) == LL.append(A, a, LL.append(A, b, c)) : List<&2, A>}

def cat_assoc(A, a, b, c):
  match a:
    case Nil{}:
      {==}
    case h <> t:
      %cat_assoc(A, t, b, c) : {h <> LL.append(A, LL.append(A, t, b), c) == h <> _ : List<&2, A>}
      {==}

law rgo_cat:
  for -A: Data
  for +xs: List<&2, A>
  for +acc: List<&2, A>
  {LL.append(A, LL.reverse.go(A, xs, Nil{}), acc) == LL.reverse.go(A, xs, acc) : List<&2, A>}

def rgo_cat(A, xs, acc):
  match xs:
    case Nil{}:
      {==}
    case h <> t:
      %rgo_cat(A, t, h <> acc) : {LL.append(A, LL.reverse.go(A, t, [h]), acc) == _ : List<&2, A>}
      %rgo_cat(A, t, [h]) : {LL.append(A, _, acc) == LL.append(A, LL.reverse.go(A, t, Nil{}), h <> acc) : List<&2, A>}
      %cat_assoc(A, LL.reverse.go(A, t, Nil{}), [h], acc) : {LL.append(A, LL.append(A, LL.reverse.go(A, t, Nil{}), [h]), acc) == _ : List<&2, A>}
      Type

#|Error:
#|- expected : {LL.append(A, LL.append(A, LL.reverse.go(A, t, []), [h]), acc) == LL.append(A, LL.append(A, LL.reverse.go(A, t, []), [h]), acc) : List<&2, A>}
#|- observed : Type
#|Context:
#|- A   : Data
#|- h   : A
#|- t   : List<&2, A>
#|- acc : List<&2, A>
#|Location: rgo_cat
#|61 |       %cat_assoc(A, LL.reverse.go(A, t, Nil{}), [h], acc) : {LL.append(A, LL.append(A, LL.reverse.go(A, t, Nil{}), [h]), acc) == _ : List<&2, A>}
#|62>|       Type
#|63 |
#|exit 1
