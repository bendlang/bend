inductive Stats where
  | leaf (sumX sumY count : UInt32)
  | node (left right : Stats)
deriving Inhabited

def word_prng (x : UInt32) : UInt32 :=
  let b := x ^^^ (x <<< 13)
  let d := b ^^^ (b >>> 17)
  d ^^^ (d <<< 5)

def value_select (test zero nonzero : UInt32) : UInt32 :=
  if test = 0 then zero else nonzero

def value_min (a b : UInt32) : UInt32 :=
  value_select (if a < b then 1 else 0) b a

def point_distance (x y centroid slot : UInt32) : UInt32 :=
  let cx := centroid &&& 65535
  let cy := centroid >>> 16
  let dx := value_select (if x < cx then 1 else 0) (x - cx) (cx - x)
  let dy := value_select (if y < cy then 1 else 0) (y - cy) (cy - y)
  ((dx * dx + dy * dy) <<< 3) ||| slot

def stats_zip : Stats → Stats → Stats
  | .leaf ax ay an, .leaf bx byv bn => .leaf (ax + bx) (ay + byv) (an + bn)
  | leaf@(.leaf _ _ _), .node _ _ => leaf
  | node@(.node _ _), .leaf _ _ _ => node
  | .node al ar, .node bl br => .node (stats_zip al bl) (stats_zip ar br)

-- 64-point leaf chunk: branchless masked adds into 24 scalar
-- accumulators (tail recursion keeps everything unboxed), one stats
-- tree materialized at the end
def stats_chunk_loop (count : Nat) (index c0 c1 c2 c3 c4 c5 c6 c7
    s0x s0y s0n s1x s1y s1n s2x s2y s2n s3x s3y s3n
    s4x s4y s4n s5x s5y s5n s6x s6y s6n s7x s7y s7n : UInt32) : Stats :=
  match count with
  | 0 =>
    .node (.node (.node (.leaf s0x s0y s0n) (.leaf s1x s1y s1n))
                 (.node (.leaf s2x s2y s2n) (.leaf s3x s3y s3n)))
          (.node (.node (.leaf s4x s4y s4n) (.leaf s5x s5y s5n))
                 (.node (.leaf s6x s6y s6n) (.leaf s7x s7y s7n)))
  | count + 1 =>
    let j : UInt32 := UInt32.ofNat (count + 1)
    let hash := word_prng ((index + j) * 2654435761)
    let x := hash &&& 1023
    let y := (hash >>> 16) &&& 1023
    let d0 := value_min (point_distance x y c0 0) (point_distance x y c1 1)
    let d1 := value_min (point_distance x y c2 2) (point_distance x y c3 3)
    let d2 := value_min (point_distance x y c4 4) (point_distance x y c5 5)
    let d3 := value_min (point_distance x y c6 6) (point_distance x y c7 7)
    let best := value_min (value_min d0 d1) (value_min d2 d3) &&& 7
    let m0 : UInt32 := if best = 0 then 1 else 0
    let m1 : UInt32 := if best = 1 then 1 else 0
    let m2 : UInt32 := if best = 2 then 1 else 0
    let m3 : UInt32 := if best = 3 then 1 else 0
    let m4 : UInt32 := if best = 4 then 1 else 0
    let m5 : UInt32 := if best = 5 then 1 else 0
    let m6 : UInt32 := if best = 6 then 1 else 0
    let m7 : UInt32 := if best = 7 then 1 else 0
    stats_chunk_loop count index c0 c1 c2 c3 c4 c5 c6 c7
      (s0x + m0*x) (s0y + m0*y) (s0n + m0)
      (s1x + m1*x) (s1y + m1*y) (s1n + m1)
      (s2x + m2*x) (s2y + m2*y) (s2n + m2)
      (s3x + m3*x) (s3y + m3*y) (s3n + m3)
      (s4x + m4*x) (s4y + m4*y) (s4n + m4)
      (s5x + m5*x) (s5y + m5*y) (s5n + m5)
      (s6x + m6*x) (s6y + m6*y) (s6n + m6)
      (s7x + m7*x) (s7y + m7*y) (s7n + m7)

def stats_chunk (index : UInt32) (centroids : Array UInt32) : Stats :=
  stats_chunk_loop 64 index centroids[0]! centroids[1]! centroids[2]!
    centroids[3]! centroids[4]! centroids[5]! centroids[6]! centroids[7]!
    0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0

def stats_fold : Nat → UInt32 → Array UInt32 → Stats
  | 0, index, centroids => stats_chunk index centroids
  | depth + 1, index, centroids =>
      stats_zip (stats_fold depth index centroids)
        (stats_fold depth (index + (64 <<< UInt32.ofNat depth)) centroids)

def stats_centroid (stats : Stats) (old : UInt32) : UInt32 :=
  match stats with
  | .node _ _ => old
  | .leaf sx sy count =>
      let divisor := if count = 0 then 1 else count
      let next := sx / divisor ||| ((sy / divisor) <<< 16)
      if count = 0 then old else next

def stats_split : Stats → Stats × Stats
  | .node left right => (left, right)
  | leaf@(.leaf _ _ _) => (leaf, .leaf 0 0 0)

def centroids_step (depth : Nat) (centroids : Array UInt32) : Array UInt32 :=
  let (a,b) := stats_split (stats_fold (depth - 6) 0 centroids)
  let (aa,ab) := stats_split a
  let (ba,bb) := stats_split b
  let pairs := #[stats_split aa, stats_split ab, stats_split ba, stats_split bb]
  let leaves := pairs.flatMap fun p => #[p.1,p.2]
  (Array.range 8).map fun k => stats_centroid leaves[k]! centroids[k]!

def centroid_initial (k : UInt32) : UInt32 :=
  let hash := word_prng (12345 + k)
  (hash &&& (1023 : UInt32)) ||| (((hash >>> 16) &&& (1023 : UInt32)) <<< 16)

def restart_loop : Nat → Nat → Array UInt32 → UInt32
  | 0, _, centroids =>
      (List.range 7).foldl (fun h k => h * (2654435761 : UInt32) + centroids[k+1]!)
        centroids[0]!
  | rounds + 1, depth, centroids =>
      restart_loop rounds depth (centroids_step depth centroids)

def restart_run (restart : UInt32) (depth : Nat) : UInt32 :=
  let base := restart * 8
  let centroids := (Array.range 8).map fun k => centroid_initial (base + UInt32.ofNat k + 1)
  restart_loop 20 depth centroids

def restart_batch : Nat → UInt32 → Nat → UInt32
  | 0, restart, depth => restart_run restart depth
  | batch + 1, restart, depth =>
      restart_batch batch restart depth +
      restart_batch batch (restart + (1 <<< UInt32.ofNat batch)) depth

def main : IO Unit := IO.println (restart_batch 6 0 19)
