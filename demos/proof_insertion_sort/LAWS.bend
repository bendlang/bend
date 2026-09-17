# proof_insertion_sort: the laws. The human states them; PROOF.bend
# must prove them. A permutation is stated by counts.

import Base
import ./main.bend as Sort

# LAW: the output of sort is sorted: it ascends, starting at 0n
law sort_sorted:
  for +xs: List<&2, Nat>
  Sort.Sorted(Sort.sort(xs))

# LAW: sort permutes its input: every value x occurs in sort(xs) as
# often as it occurs in xs
law sort_perm:
  for +x  : Nat
  for +xs : List<&2, Nat>
  {Sort.count(x, Sort.sort(xs)) == Sort.count(x, xs) : Nat}
