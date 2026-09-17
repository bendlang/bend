# Parallel sort -- the laws: mix loses no leaf, and sort keeps the leaves' sum.
import Base
import ./main.bend as Sort

# LAW: the leaves of x and y are their lesser leaves plus their greater leaves
law mix_leaves:
  for +d: Nat
  for +s: Bool
  for +x: Sort.Tree(d)
  for +y: Sort.Tree(d)
  {Nat.add(Sort.sum(d, x), Sort.sum(d, y)) == Nat.add(Sort.sum(d, Sort.mix(d, s, x, y)), Sort.sum(d, Sort.mix(d, Bool.not(s), x, y))) : Nat}

# LAW: sort keeps the sum of the leaves, for any tree and direction
law sort_leaves:
  for +d: Nat
  for s: Bool
  for +t: Sort.Tree(d)
  {Sort.sum(d, t) == Sort.sum(d, Sort.sort(d, s, t)) : Nat}
