# proof_insertion_sort: the laws. The human states them; PROOF.bend
# must prove them. A permutation is stated by counts.

import Base
import ./main.bend as Sort
import ./SPEC.bend as Spec

# LAW: the output of sort is sorted: it ascends, starting at 0n
law sort_sorted:
  for +xs: List<&2, Nat>
  Spec.Sorted(Sort.sort(xs))

# LAW: sort permutes its input: every value x occurs in sort(xs) as
# often as it occurs in xs
law sort_perm:
  for +x  : Nat
  for +xs : List<&2, Nat>
  {Spec.count(x, Sort.sort(xs)) == Spec.count(x, xs) : Nat}
