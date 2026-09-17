-- Lean twin of main.bend: a hash table with separate chaining over
-- 2^S independent tables. Same xorshift key of the seed and draw index
-- masked to 20 bits, same low-12-bit bucket, same walk (it stops at
-- the found key; Bend's stops one node later), same head insert, same
-- hit count, same position-weighted fold over the chain lengths, same
-- sum over the table tree, wrapping-u32 numerics (UInt32). A table is
-- an Array (List UInt32) of 4096 buckets, consed onto in place while
-- uniquely referenced (Array.modify); the runtime's reference counts
-- play the role of the linear frees.
def TABLES : Nat := 11
def KEYS : Nat := 16384

def word_prng (x : UInt32) : UInt32 :=
  let b := x ^^^ (x <<< (13 : UInt32))
  let d := b ^^^ (b >>> (17 : UInt32))
  d ^^^ (d <<< (5 : UInt32))

-- a key: the hash of a seed and a draw index, masked to 20 bits
def draw_key (s j : UInt32) : UInt32 :=
  word_prng (((j + 1) * 2654435761) ^^^ (s * 340573321)) &&& 1048575

-- the chain walk: 1 when the key is in the chain, stopping at it
def chain_has : List UInt32 → UInt32 → UInt32
  | [], _ => 0
  | h :: t, k => if h == k then 1 else chain_has t k

-- one insert: a present key leaves the bucket untouched, an absent
-- one is consed onto the chain
def table_ins (t : Array (List UInt32)) (k : UInt32) :
    Array (List UInt32) :=
  t.modify (k &&& 4095).toNat fun c =>
    if chain_has c k == 1 then c else k :: c

-- one table: D inserts from the table seed, D lookups from the second
-- seed, then the bucket sweep: lengths summed (the distinct count) and
-- mixed position-weighted, sealed with the hit count
def table_run (ti : UInt32) (d : Nat) : UInt32 := Id.run do
  let mut t : Array (List UInt32) := Array.replicate 4096 []
  let s := (ti + 1) * 2654435761
  for j in [0:d] do
    t := table_ins t (draw_key s (UInt32.ofNat j))
  let s2 := word_prng s
  let mut hits : UInt32 := 0
  for j in [0:d] do
    let k := draw_key s2 (UInt32.ofNat j)
    hits := hits + chain_has t[(k &&& 4095).toNat]! k
  let mut cnt : UInt32 := 0
  let mut acc : UInt32 := 0
  for i in [0:4096] do
    let l := UInt32.ofNat t[i]!.length
    cnt := cnt + l
    acc := (acc * 2654435761) ^^^ (l * (UInt32.ofNat i + 3))
  return (acc ^^^ (hits * 2654435761)) + cnt * 340573321

-- batch tree over the table index space: table checksums sum up
def batch_run : Nat → UInt32 → Nat → UInt32
  | 0, t, d => table_run t d
  | p + 1, t, d =>
      let a := batch_run p t d
      let b := batch_run p (t + (1 <<< UInt32.ofNat p)) d
      a + b

def main : IO Unit :=
  IO.println (batch_run TABLES 0 KEYS)
