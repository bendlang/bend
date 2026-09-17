-- Native Lean twin of main.bend: Conway soup census. Same
-- bit-packed 4x4-torus step, SWAR popcount, two-probe classification,
-- 64-soup chunks and census merge, wrapping-u32 numerics (UInt32).
inductive Cls where
  | still
  | osc
  | chaos

structure Census where
  pop : UInt32
  still : UInt32
  osc : UInt32
  mix : UInt32

def cell_get (board r c : UInt32) : UInt32 :=
  (board >>> (((r &&& 3) * 4 + (c &&& 3)) &&& 31)) &&& 1

def neighbor_count (board r c : UInt32) : UInt32 :=
  cell_get board (r - 1) (c - 1) + cell_get board (r - 1) c +
  cell_get board (r - 1) (c + 1) + cell_get board r (c - 1) +
  cell_get board r (c + 1) + cell_get board (r + 1) (c - 1) +
  cell_get board (r + 1) c + cell_get board (r + 1) (c + 1)

def to_bool (k : UInt32) : UInt32 := if k = 0 then 0 else 1

def next_dead (n : UInt32) : UInt32 := to_bool (if n = 3 then 1 else 0)

def next_alive (n : UInt32) : UInt32 :=
  to_bool ((if n = 2 then 1 else 0) ||| (if n = 3 then (1 : UInt32) else 0))

def next_cell (a n : UInt32) : UInt32 :=
  if a = 0 then next_dead n else next_alive n

def step_cell (board pos : UInt32) : UInt32 :=
  let r := pos >>> 2
  let c := pos &&& 3
  let alive := cell_get board r c
  let neighbors := neighbor_count board r c
  next_cell alive neighbors <<< (pos &&& 31)

def board_step (b : UInt32) : UInt32 :=
  step_cell b 0 ||| step_cell b 1 ||| step_cell b 2 ||| step_cell b 3 |||
  step_cell b 4 ||| step_cell b 5 ||| step_cell b 6 ||| step_cell b 7 |||
  step_cell b 8 ||| step_cell b 9 ||| step_cell b 10 ||| step_cell b 11 |||
  step_cell b 12 ||| step_cell b 13 ||| step_cell b 14 ||| step_cell b 15

def board_run : Nat → UInt32 → UInt32
  | 0, board => board
  | n + 1, board => board_run n (board_step board)

-- 16-bit SWAR population count
def board_popcount (b : UInt32) : UInt32 :=
  let a : UInt32 := b - ((b >>> (1 : UInt32)) &&& (21845 : UInt32))
  let c : UInt32 := (a &&& (13107 : UInt32)) + ((a >>> (2 : UInt32)) &&& (13107 : UInt32))
  let d : UInt32 := (c + (c >>> (4 : UInt32))) &&& (3855 : UInt32)
  ((d * 257) >>> (8 : UInt32)) &&& (31 : UInt32)

-- classify the settled board by two probe steps
def board_classify (b : UInt32) : Cls :=
  let n1 := board_step b
  if n1 = b then .still
  else if board_step n1 = b then .osc
  else .chaos

-- one soup: hash the soup index into a 16-bit board, run GENS steps
def soup_sim (ix : UInt32) (g : Nat) : UInt32 :=
  board_run g ((ix * 2654435761) &&& 65535)

-- leaf chunk: 64 soups folded into scalar accumulators
def chunk_run : Nat → UInt32 → Nat → UInt32 → UInt32 → UInt32 → UInt32 → Census
  | 0, _, _, pa, sa, oa, mx => ⟨pa, sa, oa, mx⟩
  | j + 1, i, g, pa, sa, oa, mx =>
      let bd := soup_sim (i + UInt32.ofNat (j + 1) - 1) g
      let p := board_popcount bd
      let m2 := (mx * 2654435761) ^^^ bd
      match board_classify bd with
      | .still => chunk_run j i g (pa + p) (sa + 1) oa m2
      | .osc => chunk_run j i g (pa + p) sa (oa + 1) m2
      | .chaos => chunk_run j i g (pa + p) sa oa m2

def census_zip (a b : Census) : Census :=
  ⟨a.pop + b.pop, a.still + b.still, a.osc + b.osc,
    a.mix * 2654435761 + b.mix⟩

def batch_run : Nat → UInt32 → Nat → Census
  | 0, i, g => chunk_run 64 i g 0 0 0 0
  | d + 1, i, g =>
      let a := batch_run d i g
      let b := batch_run d (i + (64 <<< UInt32.ofNat d)) g
      census_zip a b

-- final checksum: mix the census fields
def census_fin (c : Census) : UInt32 :=
  ((c.pop * 2654435761 + c.still) * 2654435761 + c.osc) * 2654435761 + c.mix

def main : IO Unit :=
  IO.println (census_fin (batch_run 18 0 32))
