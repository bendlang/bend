# base List: reverse is involutive and an insertion sort orders (dupes
# kept) on concrete lists -- closed by conversion alone, no output.
# ported from bend3: list literals become Con/Nil spines, bend3-base
# List.sort becomes a local insertion sort (bend base has none); the
# compare-and-rebuild double use takes + binders (List<&2, U32> is
# Data, so it duplicates)
import Base

law l123:
  List<&2, U32>

def l123():
  [1, 2, 3]

law l321:
  List<&2, U32>

def l321():
  [3, 2, 1]

law insert.put:
  for +x: U32
  for  h: U32
  for +t: List<&2, U32>
  for  r: List<&2, U32>
  for  f: Bool
  List<&2, U32>

def insert.put(x, h, t, r, f):
  match f:
    case True{}:
      x <> h <> t
    case False{}:
      h <> r

law insert:
  for +x  : U32
  for +xs : List<&2, U32>
  List<&2, U32>

def insert(x, xs):
  match xs:
    case Nil{}:
      [x]
    case h <> t:
      insert.put(x, h, t, insert(x, t), U32.is_le(x, h))

law sort:
  for xs: List<&2, U32>
  List<&2, U32>

def sort(xs):
  match xs:
    case Nil{}:
      Nil{}
    case h <> t:
      insert(h, sort(t))

law rev:
  {List.reverse(&2, U32, l123) == l321 : List<&2, U32>}

def rev():
  {==}

law rev2:
  {List.reverse(&2, U32, List.reverse(&2, U32, l123)) == l123 : List<&2, U32>}

def rev2():
  {==}

law srt:
  {sort([3, 1, 2, 3]) == [1, 2, 3, 3] : List<&2, U32>}

def srt():
  {==}

#|All terms check.
