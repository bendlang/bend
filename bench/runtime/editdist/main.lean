-- Native Lean twin of main.bend: Levenshtein edit distance by dynamic
-- programming, single-threaded, 1-to-1 with the Bend program: the same
-- xorshift symbol streams (sequences are ByteArrays), the same two
-- rolling Array UInt32 rows swapping roles after every row (updated in
-- place while uniquely referenced), the same min chain and cost test
-- per cell, and the same checksum fold over the pair index space.
def DEPTH : Nat := 15
def N : Nat := 256

def word_prng (x : UInt32) : UInt32 :=
  let b := x ^^^ (x <<< (13 : UInt32))
  let d := b ^^^ (b >>> (17 : UInt32))
  d ^^^ (d <<< (5 : UInt32))

-- draw one sequence: step the stream, keep its low two bits
def seq_gen (s0 : UInt32) : ByteArray := Id.run do
  let mut s := s0
  let mut x := ByteArray.emptyWithCapacity N
  for _ in [0:N] do
    s := word_prng s
    x := x.push (s &&& 3).toUInt8
  return x

-- the DP: prev[j] = j at the start; row i reads a[i] once, writes
-- cur[0] = i + 1, fills cur[1..N], then the rows swap roles
def edit_dist (a b : ByteArray) : UInt32 := Id.run do
  let mut prev : Array UInt32 := Array.replicate (N + 1) 0
  let mut cur : Array UInt32 := Array.replicate (N + 1) 0
  for k in [0:N + 1] do
    prev := prev.set! k (UInt32.ofNat k)
  for i in [0:N] do
    let ai := a.get! i
    cur := cur.set! 0 (UInt32.ofNat i + 1)
    for j in [0:N] do
      let cost : UInt32 := if ai != b.get! j then 1 else 0
      cur := cur.set! (j + 1)
        (min (min (prev[j + 1]! + 1) (cur[j]! + 1)) (prev[j]! + cost))
    let t := prev
    prev := cur
    cur := t
  return prev[N]!

-- one pair: seed from the hashed pair index, draw a and b, run the
-- DP, mix the distance with the index
def pair_run (p : UInt32) : UInt32 :=
  let s := (p + 1) * 2654435761
  let a := seq_gen s
  let b := seq_gen (s * 340573321)
  (edit_dist a b * 2654435761) ^^^ (p + 1)

def batch_run : Nat → UInt32 → UInt32
  | 0, p => pair_run p
  | d + 1, p =>
      let x := batch_run d p
      let y := batch_run d (p + (1 <<< UInt32.ofNat d))
      x + y

def main : IO Unit :=
  IO.println (batch_run DEPTH 0)
