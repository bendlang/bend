-- Lean twin of main.bend: same Speck32/64 leaf stream, Merkle
-- tree build, audit re-fold, scalar-prover proof extraction and proof
-- verification, single-threaded. All values are UInt32 (wrapping, like
-- Bend words); round/depth counters are Nat pattern-matched
-- structurally.
inductive Mt where
  | leaf (h : UInt32)
  | node (h : UInt32) (l r : Mt)

inductive Path where
  | nil
  | cons (side sib : UInt32) (rest : Path)

def SIZE : Nat := 22
def BLOCKS : Nat := 30
def PROBE : UInt32 := 1337

def ROUND_KEYS : Array UInt32 :=
  #[256, 5394, 24957, 5208, 26905, 30690, 3209, 52443, 61418, 20019, 30452,
    22902, 61067, 56068, 17943, 62334, 34740, 36554, 60827, 14930, 33321,
    60772]

def round_key (i : UInt32) : UInt32 :=
  ROUND_KEYS[(if i < 21 then i else 21).toNat]!

-- 22 Speck rounds over the 16-bit halves x, y
def speck_run : Nat → UInt32 → UInt32 → UInt32 → UInt32
  | 0, _, x, y => x ||| (y <<< 16)
  | r + 1, j, x, y =>
      let nx := ((((((x >>> 7) ||| (x <<< 9)) &&& 65535) + y) &&& 65535) ^^^
        round_key j) &&& 65535
      speck_run r (j + 1) nx (((((y <<< 2) ||| (y >>> 14)) &&& 65535) ^^^ nx)
        &&& 65535)

-- one leaf: encrypt `count` counter blocks, chain the ciphertexts
def block_chain : Nat → UInt32 → UInt32 → UInt32
  | 0, _, acc => acc
  | c + 1, b, acc =>
      block_chain c (b + 1)
        (acc * (2654435761 : UInt32) + speck_run 22 0 (b &&& 65535) ((b >>> 16) &&& 65535))

def leaf_hash (b : UInt32) : UInt32 :=
  block_chain BLOCKS (b * UInt32.ofNat BLOCKS) (b + 1)

-- Merkle join: ARX mix of the two child hashes
def hash_join (a b : UInt32) : UInt32 :=
  let h := (a * (2654435761 : UInt32)) ^^^ b
  let h2 := ((h + (2246822519 : UInt32)) * (2246822519 : UInt32)) ^^^ (h >>> 13)
  h2 ^^^ (h2 >>> 16)

-- the scalar prover: recompute a subtree hash without materializing it
def hash_tree : Nat → UInt32 → UInt32
  | 0, b => leaf_hash b
  | d + 1, b =>
      hash_join (hash_tree d b) (hash_tree d (b + ((1 : UInt32) <<< UInt32.ofNat d)))

def mt_hash : Mt → UInt32
  | .leaf h => h
  | .node h _ _ => h

-- join two subtrees into a hashed node (peek the child hashes)
def mt_join (l r : Mt) : Mt :=
  .node (hash_join (mt_hash l) (mt_hash r)) l r

-- build the Merkle tree over blocks b .. b + 2^d - 1
def mt_build : Nat → UInt32 → Mt
  | 0, b => .leaf (leaf_hash b)
  | d + 1, b =>
      mt_join (mt_build d b) (mt_build d (b + ((1 : UInt32) <<< UInt32.ofNat d)))

-- audit: re-fold the tree; any stored-hash mismatch perturbs the result
def mt_audit : Mt → UInt32
  | .leaf h => h
  | .node h l r =>
      let m := hash_join (mt_audit l) (mt_audit r)
      m + (m ^^^ h)

-- Merkle proof for leaf k: per level, the side bit and the sibling hash
def path_gen : Nat → UInt32 → UInt32 → Path
  | 0, _, _ => .nil
  | d + 1, k, b =>
      let bit := (k >>> UInt32.ofNat d) &&& 1
      let half := (1 : UInt32) <<< UInt32.ofNat d
      let sib := hash_tree d (if bit == 0 then b + half else b)
      .cons bit sib (path_gen d k (if bit == 0 then b else b + half))

-- fold the proof back up from the leaf hash to a root hash
def path_verify : Path → UInt32 → UInt32
  | .nil, lh => lh
  | .cons s sib rest, lh =>
      let hh := path_verify rest lh
      if s == 0 then hash_join hh sib else hash_join sib hh

def main : IO Unit := do
  let t := mt_build SIZE 0
  let root := mt_audit t
  let prf := path_gen SIZE PROBE 0
  IO.println (hash_join root (path_verify prf (leaf_hash PROBE)))
