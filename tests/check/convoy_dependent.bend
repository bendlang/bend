# a match carries a variable its arms use more than once (q=1, not Data)
# into them, and each arm binds it again; a later variable whose type
# names it stayed out, at its type outside the arms, so the kernel saw
# {x1 == x0} where the arm's Box needs {x4 == x0} (#1292). It now rides
# too, at its own quantity: erased (pick), live (pick_live), into a match
# in one arm (pick_inner), three matches deep, where an arm built again
# sees an inner match only by the variables it names, so a dead use
# there counts too (pick_deep), into a
# default arm (pick_rest) and past a self-call (pick_rec). The law checks
# main's value in the emitted book too
import Base

type Owner is Type:
  Owner{n: Nat}

type Box<-original: Owner> is Type:
  Box{owner: Owner, -same: {owner == original : Owner}}

type Three is Data:
  One{}
  Two{}
  Many{}

def pick(-original: Owner, owner: Owner, -same: {owner == original : Owner}, flag: Bool) -> Box<original>:
  match flag:
    case False{}:
      Box{owner, same}
    case True{}:
      Box{owner, same}

def pick_live(-original: Owner, owner: Owner, same: {owner == original : Owner}, flag: Bool) -> Box<original>:
  match flag:
    case False{}:
      Box{owner, same}
    case True{}:
      Box{owner, same}

def pick_inner(-original: Owner, owner: Owner, -same: {owner == original : Owner}, a: Bool, b: Bool) -> Box<original>:
  match a:
    case False{}:
      match b:
        case False{}:
          Box{owner, same}
        case True{}:
          Box{owner, same}
    case True{}:
      Box{owner, same}

def pick_deep(-original: Owner, owner: Owner, -same: {owner == original : Owner}, a: Bool, b: Bool, c: Bool) -> Box<original>:
  match a:
    case False{}:
      match b:
        case False{}:
          match c:
            case False{}:
              Box{owner, same}
            case True{}:
              Box{owner, same}
        case True{}:
          match c:
            case False{}:
              Box{owner, same}
            case True{}:
              Box{owner, same}
    case True{}:
      Box{owner, same}

def pick_rest(-original: Owner, owner: Owner, -same: {owner == original : Owner}, t: Three) -> Box<original>:
  match t:
    case One{}:
      Box{owner, same}
    case _:
      Box{owner, same}

def pick_rec(-original: Owner, owner: Owner, -same: {owner == original : Owner}, k: Nat) -> Box<original>:
  match k:
    case 0n:
      Box{owner, same}
    case 1n+p:
      pick_rec(original, owner, same, p)

def num(-original: Owner, box: Box<original>) -> Nat:
  match box:
    case Box{owner, same}:
      match owner:
        case Owner{n}:
          n

def main() -> Nat:
  Nat.add(num(Owner{1n}, pick(Owner{1n}, Owner{1n}, {==}, True{})),
  Nat.add(num(Owner{2n}, pick_live(Owner{2n}, Owner{2n}, {==}, False{})),
  Nat.add(num(Owner{3n}, pick_inner(Owner{3n}, Owner{3n}, {==}, False{}, True{})),
  Nat.add(num(Owner{4n}, pick_deep(Owner{4n}, Owner{4n}, {==}, False{}, False{}, True{})),
  Nat.add(num(Owner{5n}, pick_rest(Owner{5n}, Owner{5n}, {==}, Many{})),
    num(Owner{6n}, pick_rec(Owner{6n}, Owner{6n}, {==}, 2n)))))))

law convoy_dependent_result:
  {main() == 21n : Nat}

def convoy_dependent_result():
  {==}

#|21n
