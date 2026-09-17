# Parallel sum -- the law: the fork/join tree adds the same numbers as the
# sequential loop seq. PROOF.bend proves it by induction on the depth.
import Base
import ./main.bend as Par

# LAW: the tree of depth d at i adds i, i + 1, .., i + 2^d - 1, for any d and i
law tree_is_seq:
  for +d: Nat
  for +i: Nat
  {Par.sum(d, i) == Par.seq(Par.pow2(d), i) : Nat}
