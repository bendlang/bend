# proof_insertion_sort: the proofs, by induction on the list. Each
# insert lemma has a .fin half that takes the verdict le_case(x, h) as
# a parameter c and matches it, since a computed value cannot be
# matched in place; the induction hypothesis arrives as rec.

import Base
import ./main.bend as Sort
import ./SPEC.bend as Spec
import ./LAWS.bend as Laws

# Sortedness
# ----------
# inserting x into a list bounded by lo keeps the bound when lo <= x:
# in the Inl arm x heads the result, in the Inr arm h stays the head
# and the recursion inserts x into t under the bound h

def sorted_ins.fin(-lo: Nat, -x: Nat, -h: Nat, -t: List<&2, Nat>, sx: Spec.Sorted.from(lo, h <> t), lx: Spec.LE(lo, x),
  rec: Spec.Sorted.from(h, t) -> Spec.LE(h, x) -> Spec.Sorted.from(h, Sort.insert(x, t)), c: Or(Spec.LE(x, h), Spec.LE(h, x)))
  -> Spec.Sorted.from(lo, Sort.dec(x, h, t, Sort.insert(x, t), c)):
  (lh, st) = sx
  match c:
    case Inl{e}:
      (lx, e, st)
    case Inr{e}:
      (lh, rec(st, e))

def sorted_ins(xs: List<&2, Nat>, -lo: Nat, +x: Nat) -> Spec.Sorted.from(lo, xs) -> Spec.LE(lo, x) -> Spec.Sorted.from(lo, Sort.insert(x, xs)):
  match xs:
    case Nil{}:
      sx => lx => (lx, Unit{})
    case h <> t:
      sx => lx => sorted_ins.fin(lo, x, h, t, sx, lx, sorted_ins(t, h, x), Sort.le_case(x, h))

# sort(h <> t) inserts h into the sorted sort(t); 0n bounds everything
def Laws.sort_sorted(xs):
  match xs:
    case Nil{}:
      Unit{}
    case h <> t:
      sorted_ins(Sort.sort(t), 0n, h)(Laws.sort_sorted(t), Unit{})

# Permutation
# -----------
# count(x, y <> ys) is bump(x == y, count(x, ys)). insert moves y past
# the heads it exceeds; bump_swap moves y's bump past theirs.

def bump_swap(a: Bool, b: Bool, -n: Nat) -> {Spec.bump(a, Spec.bump(b, n)) == Spec.bump(b, Spec.bump(a, n)) : Nat}:
  match a b:
    case True{} True{}:
      {==}
    case True{} False{}:
      {==}
    case False{} True{}:
      {==}
    case False{} False{}:
      {==}

# inserting y into xs adds y's bump to every count, as consing y does
def count_ins.fin(+x: Nat, y: Nat, h: Nat, -t: List<&2, Nat>, rec: {Spec.count(x, y <> t) == Spec.count(x, Sort.insert(y, t)) : Nat}, c: Or(Spec.LE(y, h), Spec.LE(h, y)))
  -> {Spec.count(x, y <> h <> t) == Spec.count(x, Sort.dec(y, h, t, Sort.insert(y, t), c)) : Nat}:
  match c:
    case Inl{e}:
      {==}
    case Inr{e}:
      %rec : {Spec.count(x, y <> h <> t) == Spec.bump(Cmp.is_eq(Nat.cmp(x, h)), _) : Nat}
      bump_swap(Cmp.is_eq(Nat.cmp(x, y)), Cmp.is_eq(Nat.cmp(x, h)), Spec.count(x, t))

def count_ins(+x: Nat, +y: Nat, +xs: List<&2, Nat>) -> {Spec.count(x, y <> xs) == Spec.count(x, Sort.insert(y, xs)) : Nat}:
  match xs:
    case Nil{}:
      {==}
    case h <> t:
      count_ins.fin(x, y, h, t, count_ins(x, y, t), Sort.le_case(y, h))

# count(x, sort(h <> t)) is count(x, insert(h, sort(t))): count_ins
# turns it into count(x, h <> sort(t)), and the IH closes the tail
def Laws.sort_perm(x, xs):
  match xs:
    case Nil{}:
      {==}
    case h <> t:
      %count_ins(x, h, Sort.sort(t)) : {_ == Spec.bump(Cmp.is_eq(Nat.cmp(x, h)), Spec.count(x, t)) : Nat}
      %Laws.sort_perm(x, t) : {Spec.bump(Cmp.is_eq(Nat.cmp(x, h)), Spec.count(x, Sort.sort(t))) == Spec.bump(Cmp.is_eq(Nat.cmp(x, h)), _) : Nat}
      {==}
