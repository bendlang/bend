-- Lean twin of main.bend: same trie sort (gen -> to_map/merge ->
-- to_arr) and Chk verification scan, single-threaded. Keys are UInt32
-- (wrapping, like Bend words); depth counters are Nat pattern-matched
-- structurally.
inductive Arr where
  | empty
  | single (v : UInt32)
  | concat (l r : Arr)

inductive MapTree where
  | free
  | busy
  | node (l r : MapTree)

inductive Chk where
  | nil
  | val (lo hi ok cnt sum : UInt32)

def DEPTH : Nat := 22

def word_prng (x : UInt32) : UInt32 :=
  let b := x ^^^ (x <<< 13)
  let d := b ^^^ (b >>> 17)
  d ^^^ (d <<< 5)

def word_key (i : UInt32) : UInt32 :=
  word_prng ((i + 1) * 2654435761) &&& 16777215

def map_merge : MapTree → MapTree → MapTree
  | .free, b => b
  | a, .free => a
  | .busy, _ => .busy
  | _, .busy => .busy
  | .node a b, .node c d => .node (map_merge a c) (map_merge b d)

def arr_generate : Nat → UInt32 → Arr
  | 0, x => .single (word_key x)
  | n + 1, x => .concat (arr_generate n (x * 2)) (arr_generate n (x * 2 + 1))

def map_swap_bits (test : UInt32) (zero one : MapTree) : MapTree :=
  if test == 0 then .node zero one else .node one zero

def map_radix : Nat → UInt32 → UInt32 → MapTree → MapTree
  | 0, _, _, r => r
  | i + 1, n, k, r => map_radix i n (k * 2) (map_swap_bits (n &&& k) r .free)

def arr_to_map : Arr → MapTree
  | .empty => .free
  | .single x => map_radix 24 x 1 .busy
  | .concat a b => map_merge (arr_to_map a) (arr_to_map b)

def map_to_arr : MapTree → UInt32 → Arr
  | .free, _ => .empty
  | .busy, k => .single k
  | .node l r, k => .concat (map_to_arr l (k * 2)) (map_to_arr r (k * 2 + 1))

def chk_join : Chk → Chk → Chk
  | .nil, b => b
  | a, .nil => a
  | .val alo ahi aok acnt asum, .val blo bhi bok bcnt bsum =>
      .val alo bhi ((aok &&& bok) &&& (if ahi < blo then 1 else 0))
        (acnt + bcnt) (asum + bsum)

def arr_chk : Arr → Chk
  | .empty => .nil
  | .single x => .val x x 1 1 x
  | .concat a b => chk_join (arr_chk a) (arr_chk b)

def chk_out : Chk → UInt32
  | .nil => 0
  | .val lo hi ok cnt sum =>
      ((sum + cnt * 2654435761) ^^^ (hi + lo * 340573321)) + ok * 2246822519

def arr_sort (a : Arr) : Arr :=
  map_to_arr (arr_to_map a) 0

def main : IO Unit :=
  IO.println (chk_out (arr_chk (arr_sort (arr_generate DEPTH 0))))
