-- Lean twin of main.bend: same tree-shaped bitonic sorting
-- network, key generator and Stat verification scan, single-threaded.
-- All values are UInt32 (wrapping, like Bend words); depth counters are
-- Nat pattern-matched structurally; flow is `partial` (its termination
-- is lexicographic on (d, mode), which Lean does not infer).
inductive Tree where
  | leaf (v : UInt32)
  | node (l r : Tree)

instance : Inhabited Tree := ⟨.leaf 0⟩

structure Stat where
  lo : UInt32
  hi : UInt32
  ok : UInt32
  mx : UInt32

def SIZE : Nat := 23

def word_prng (x : UInt32) : UInt32 :=
  let b := x ^^^ (x <<< 13)
  let d := b ^^^ (b >>> 17)
  d ^^^ (d <<< 5)

def word_key (i : UInt32) : UInt32 :=
  word_prng ((i + 1) * 2654435761)

@[inline] def tree_swap (s a b : UInt32) : Tree :=
  if s == 0 then .node (.leaf a) (.leaf b) else .node (.leaf b) (.leaf a)

@[inline] def tree_warp_zip : Tree → Tree → Tree
  | .node a0 a1, .node b0 b1 => .node (.node a0 b0) (.node a1 b1)
  | _, _ => .leaf 0

def tree_warp (s : UInt32) : Tree → Tree → Tree
  | .leaf av, .leaf bv =>
      tree_swap (s ^^^ (if av > bv then 1 else 0)) av bv
  | .node aa ab, .node ba bb =>
      tree_warp_zip (tree_warp s aa ba) (tree_warp s ab bb)
  | _, _ => .leaf 0

-- mode 0 warps the halves, mode 1 descends one level shallower
partial def tree_flow : Nat → Nat → UInt32 → Tree → Tree
  | 0, _, _, t => t
  | d + 1, 0, s, .node a b => tree_flow d 1 s (tree_warp s a b)
  | _ + 1, 0, _, t => t
  | d + 1, 1, s, .node wa wb =>
      .node (tree_flow (d + 1) 0 s wa) (tree_flow (d + 1) 0 s wb)
  | _ + 1, _, _, t => t

def tree_sort1 (d : Nat) (s : UInt32) (sa sb : Tree) : Tree :=
  tree_flow d 0 s (.node sa sb)

def tree_bsort : Nat → UInt32 → UInt32 → Tree
  | 0, _, x => .leaf (word_key x)
  | d + 1, s, x =>
      tree_sort1 (d + 1) s (tree_bsort d 0 (x * 2 + 1)) (tree_bsort d 1 (x * 2))

@[inline] def stat_join (a b : Stat) : Stat :=
  ⟨a.lo, b.hi, (a.ok &&& b.ok) &&& (if a.hi <= b.lo then 1 else 0),
   a.mx * 2654435761 + b.mx⟩

def tree_scan : Nat → Tree → Stat
  | 0, .leaf v => ⟨v, v, 1, v⟩
  | 0, _ => ⟨0, 0, 0, 0⟩
  | d + 1, .node a b => stat_join (tree_scan d a) (tree_scan d b)
  | _ + 1, _ => ⟨0, 0, 0, 0⟩

def stat_out (s : Stat) : UInt32 :=
  ((s.mx * 2654435761) ^^^ (s.hi + s.lo * 340573321)) + s.ok * 2246822519

def main : IO Unit := do
  let t := tree_bsort SIZE 0 0
  IO.println (stat_out (tree_scan SIZE t))
