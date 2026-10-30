# regression witness (#1953): a fork whose first kid owns a list and whose
# second kid's argument is a spin that borrows it. The parallel path held
# the list for the join while the serial path sank it after the spin, so
# the join had fewer parameters than the fork filled: the second kid's
# task landed on the join's continuation, never ran, and the frontier
# drained at 2+ threads. Three kids, two lists and an owner between two
# spins take the same path.
import Base

type Items is Data:
  INil{}
  ICons{+x: U32, next: Items}

def Items.copy(xs: Items, acc: Items) -> Items:
  match xs:
    case INil{}:
      acc
    case ICons{+x, t}:
      Items.copy(t, ICons{x, acc})

def Items.cat(xs: Items, ys: Items) -> Items:
  match xs:
    case INil{}:
      ys
    case ICons{+x, t}:
      Items.cat(t, ICons{x, ys})

def Items.keep(xs: Items) -> Items:
  match xs:
    case INil{}:
      INil{}
    case ICons{h, t}:
      ICons{h, t}

def Items.len(xs: Items) -> U32:
  match xs:
    case INil{}:
      0
    case ICons{_, t}:
      (1 + Items.len(t) : U32)

def two(+xs: Items) -> U32:
  a b = Items.keep(xs) Items.keep(Items.copy(xs, INil{}))
  (Items.len(a) + Items.len(b) : U32)

def three(+xs: Items) -> U32:
  a b c = Items.keep(xs) Items.keep(Items.copy(xs, INil{})) Items.keep(Items.copy(xs, INil{}))
  (Items.len(a) + Items.len(b) + Items.len(c) : U32)

def pair(+xs: Items, +ys: Items) -> U32:
  a b = Items.keep(Items.cat(xs, ys)) Items.keep(Items.cat(Items.copy(xs, INil{}), Items.copy(ys, INil{})))
  (Items.len(a) + Items.len(b) : U32)

def middle(+xs: Items) -> U32:
  a b c = Items.keep(Items.copy(xs, INil{})) Items.keep(xs) Items.keep(Items.copy(xs, INil{}))
  (Items.len(a) + Items.len(b) + Items.len(c) : U32)

def main() -> IO(Unit):
  IO.print(U32.show(two(ICons{7, INil{}})) ++ " " ++ U32.show(three(ICons{7, INil{}})) ++ " " ++ U32.show(pair(ICons{7, INil{}}, ICons{8, ICons{9, INil{}}})) ++ " " ++ U32.show(middle(ICons{7, INil{}})))

#|2 3 6 3
