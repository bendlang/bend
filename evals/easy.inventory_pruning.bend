# An inventory tracker merges warehouse shelf trees from left to right.
# Empty shelves are pruned and unary branches collapsed. Prove this
# cleanup preserves the order of every item in the merged inventory.
import Base

type Shelf is Data:
  Vacant{}
  Stock{item: Nat}
  Aisle{left: Shelf, right: Shelf}

def cat(xs: List<Nat>, ys: List<Nat>) -> List<Nat>:
  match xs:
    case Nil{}: ys
    case Con{h, t}: Con{h, cat(t, ys)}

def items(s: Shelf) -> List<Nat>:
  match s:
    case Vacant{}: Nil{}
    case Stock{item}: [item]
    case Aisle{left, right}: cat(items(left), items(right))

def join(a: Shelf, b: Shelf) -> Shelf:
  match a:
    case Vacant{}: b
    case Stock{item}:
      match b:
        case Vacant{}: Stock{item}
        case Stock{other}: Aisle{Stock{item}, Stock{other}}
        case Aisle{left, right}: Aisle{Stock{item}, Aisle{left, right}}
    case Aisle{left, right}:
      match b:
        case Vacant{}: Aisle{left, right}
        case Stock{item}: Aisle{Aisle{left, right}, Stock{item}}
        case Aisle{x, y}: Aisle{Aisle{left, right}, Aisle{x, y}}

def prune(s: Shelf) -> Shelf:
  match s:
    case Vacant{}: Vacant{}
    case Stock{item}: Stock{item}
    case Aisle{left, right}: join(prune(left), prune(right))

law merged_inventory:
  for a: Shelf
  for b: Shelf
  {items(prune(Aisle{a, b})) == cat(items(a), items(b)) : List<Nat>}

# solution
law cat_empty:
  for xs: List<Nat>
  {xs == cat(xs, Nil{}) : List<Nat>}

def cat_empty(xs):
  match xs:
    case Nil{}: {==}
    case Con{h, t}:
      %cat_empty(t) : {Con{h, t} == Con{h, _} : List<Nat>}
      {==}

law join_items:
  for a: Shelf
  for +b: Shelf
  {items(join(a, b)) == cat(items(a), items(b)) : List<Nat>}

def join_items(a, b):
  match a:
    case Vacant{}: {==}
    case Stock{n}:
      match b:
        case Vacant{}: {==}
        case Stock{k}: {==}
        case Aisle{l, r}: {==}
    case Aisle{l, r}:
      match b:
        case Vacant{}:
          cat_empty(cat(items(l), items(r)))
        case Stock{k}: {==}
        case Aisle{x, y}: {==}

law prune_items:
  for s: Shelf
  {items(prune(s)) == items(s) : List<Nat>}

def prune_items(s):
  match s:
    case Vacant{}: {==}
    case Stock{item}: {==}
    case Aisle{+left, +right}:
      -out = items(join(prune(left), prune(right)))
      %prune_items(left) : {out == cat(_, items(right)) : List<Nat>}
      %prune_items(right) : {out == cat(items(prune(left)), _) : List<Nat>}
      join_items(prune(left), prune(right))

def merged_inventory(a, b):
  prune_items(Aisle{a, b})
