-- Lean twin of main.bend: breadth-first search over 2^DEPTH
-- independent 32x32 grid mazes, single-threaded, 1-to-1 with the Bend
-- program: same seed and wall hash, an Array UInt32 grid (1 open, 0
-- wall), an Array UInt32 queue with head and tail, an Array UInt32
-- distance map seeded unseen, the textbook pop loop with four
-- bounds-checked neighbour looks, and the same position-weighted fold
-- sealed by the reached count. The arrays live in one Bfs structure
-- that every step consumes and rebuilds, so each stays uniquely
-- referenced and set! writes in place; leaf checksums sum up the
-- batch recursion.
def DEPTH : Nat := 19
def CELLS : Nat := 1024
def UNSEEN : UInt32 := 0xFFFFFFFF

structure Bfs where
  g : Array UInt32
  q : Array UInt32
  d : Array UInt32
  head : UInt32
  tail : UInt32

def word_prng (x : UInt32) : UInt32 :=
  let b := x ^^^ (x <<< (13 : UInt32))
  let d := b ^^^ (b >>> (17 : UInt32))
  d ^^^ (d <<< (5 : UInt32))

-- 1 when cell c of the maze seeded s is open: the start always, any
-- other cell when its hash mod 100 is 30 or more (30% walls)
def cell_open (s c : UInt32) : UInt32 :=
  let h := word_prng (s ^^^ ((c + 1) * 340573321))
  if c == 0 || h % 100 >= 30 then 1 else 0

-- one neighbour n at distance v: skip it out of bounds, a wall or
-- seen; else stamp its distance and push it
def bfs_look (b : Bfs) (n v : UInt32) (inb : Bool) : Bfs :=
  if inb && b.g[n.toNat]! != 0 && b.d[n.toNat]! == UNSEEN then
    { b with d := b.d.set! n.toNat v, q := b.q.set! b.tail.toNat n,
             tail := b.tail + 1 }
  else
    b

-- one pop: the head cell and its distance, then its four neighbours
def bfs_pop (b : Bfs) : Bfs :=
  let c := b.q[b.head.toNat]!
  let v := b.d[c.toNat]! + 1
  let x := c &&& 31
  let y := c >>> (5 : UInt32)
  let b := { b with head := b.head + 1 }
  let b := bfs_look b (c - 1) v (x > 0)
  let b := bfs_look b (c + 1) v (x < 31)
  let b := bfs_look b (c - 32) v (y > 0)
  bfs_look b (c + 32) v (y < 31)

-- the search loop, fuel-bounded by the cell count (a cell is pushed
-- once at most); it stops when the queue drains
def bfs_run : Nat → Bfs → Bfs
  | 0, b => b
  | f + 1, b => if b.head < b.tail then bfs_run f (bfs_pop b) else b

-- the leaf checksum: a reached cell mixes its distance position-
-- weighted and counts one; the count seals the mix
def bfs_fold (b : Bfs) : UInt32 := Id.run do
  let mut acc : UInt32 := 0
  let mut cnt : UInt32 := 0
  for c in [0:CELLS] do
    let v := b.d[c]!
    let hit : UInt32 := if v != UNSEEN then 1 else 0
    let w := if hit == 1 then v * (UInt32.ofNat c + 1) else 0
    acc := (acc * 2654435761) ^^^ w
    cnt := cnt + hit
  return acc ^^^ (cnt * 2246822519)

-- one maze: fill the grid, seed the search with cell 0 at distance 0,
-- search, fold
def maze_run (m : UInt32) : UInt32 := Id.run do
  let s := (m + 1) * 2654435761
  let mut g : Array UInt32 := Array.replicate CELLS 0
  for c in [0:CELLS] do
    g := g.set! c (cell_open s (UInt32.ofNat c))
  let d := (Array.replicate CELLS UNSEEN).set! 0 0
  let q : Array UInt32 := Array.replicate CELLS 0
  let b := bfs_run CELLS { g := g, q := q, d := d, head := 0, tail := 1 }
  return bfs_fold b

def batch_run : Nat → UInt32 → UInt32
  | 0, i => maze_run i
  | k + 1, i =>
      let a := batch_run k i
      let b := batch_run k (i + (1 <<< UInt32.ofNat k))
      a + b

def main : IO Unit :=
  IO.println (batch_run DEPTH 0)
