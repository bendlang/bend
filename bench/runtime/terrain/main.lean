-- Native Lean twin of main.bend: procedural terrain tile pipeline.
-- Same value-noise fill, in-place Gauss-Seidel relaxation sweeps with
-- pass-salted roughening, 64-bin histogram and position-weighted folds,
-- wrapping-u32 numerics (UInt32; heightmaps are linear Arrays, updated
-- in place while uniquely referenced).
def word_prng (x : UInt32) : UInt32 :=
  let b := x ^^^ (x <<< (13 : UInt32))
  let d := b ^^^ (b >>> (17 : UInt32))
  d ^^^ (d <<< (5 : UInt32))

-- lattice corner hash -> 0..255
def lattice_hash (gx gz : UInt32) : UInt32 :=
  word_prng ((gx * 2654435761) ^^^ (gz * 340573321)) &&& 255

-- value noise at 8.8 fixed-point (x, z): bilinear lerp of 4 corner hashes
def terrain_ground (x z : UInt32) : UInt32 :=
  let gx := (x >>> (8 : UInt32)) &&& 63
  let gz := (z >>> (8 : UInt32)) &&& 63
  let fx := x &&& 255
  let fz := z &&& 255
  let gx1 := (gx + 1) &&& 63
  let gz1 := (gz + 1) &&& 63
  let h00 := lattice_hash gx gz
  let h10 := lattice_hash gx1 gz
  let h01 := lattice_hash gx gz1
  let h11 := lattice_hash gx1 gz1
  let t0 := (h00 * (256 - fx) + h10 * fx) >>> (8 : UInt32)
  let t1 := (h01 * (256 - fx) + h11 * fx) >>> (8 : UInt32)
  (t0 * (256 - fz) + t1 * fz) >>> (8 : UInt32)

-- noise-fill one tile: one write per cell
def tile_fill (ox oz : UInt32) (h : Array UInt32) : Array UInt32 := Id.run do
  let mut h := h
  for i in [0:4096] do
    let iw := UInt32.ofNat i
    h := h.set! i (terrain_ground ((ox + (iw &&& 63)) <<< (6 : UInt32))
      ((oz + (iw >>> (6 : UInt32))) <<< (6 : UInt32)))
  return h

-- one relaxation cell: 5 reads + 1 write, clamped neighbours,
-- pass-salted 1-bit roughening
def erode_cell (i : Nat) (p : UInt32) (h : Array UInt32) : Array UInt32 :=
  let iw := UInt32.ofNat i
  let xc := iw &&& 63
  let zc := iw >>> (6 : UInt32)
  let hc := h[i]!
  let hl := h[if xc > 0 then i - 1 else i]!
  let hr := h[if xc < 63 then i + 1 else i]!
  let hu := h[if zc > 0 then i - 64 else i]!
  let hd := h[if zc < 63 then i + 64 else i]!
  let rough := word_prng (iw ^^^ (p * 2654435761)) &&& 1
  h.set! i (((hc * 4 + hl + hr + hu + hd) >>> (3 : UInt32)) + rough)

-- one Gauss-Seidel sweep over the tile, ascending scan order
def tile_erode (p : UInt32) (h : Array UInt32) : Array UInt32 := Id.run do
  let mut h := h
  for i in [0:4096] do
    h := erode_cell i p h
  return h

def tile_smooth : Nat → Array UInt32 → Array UInt32
  | 0, h => h
  | p + 1, h => tile_smooth p (tile_erode (UInt32.ofNat (p + 1)) h)

-- histogram fold: mix every bucket count, position-weighted
def hist_fold (g : Array UInt32) (acc : UInt32) : UInt32 := Id.run do
  let mut acc := acc
  for i in [0:64] do
    acc := (acc * 2654435761) ^^^ (g[i]! * (UInt32.ofNat i + 3))
  return acc

-- per cell: read the height, bump its histogram bucket, mix the height
def tile_hist (h : Array UInt32) (acc0 : UInt32) : UInt32 := Id.run do
  let mut g : Array UInt32 := Array.replicate 64 0
  let mut acc := acc0
  for i in [0:4096] do
    let v := h[i]!
    let b := ((v >>> (2 : UInt32)) &&& 63).toNat
    g := g.set! b (g[b]! + 1)
    acc := acc * 2654435761 + v * (UInt32.ofNat i + 1)
  return hist_fold g acc

-- one tile: fill, EPASS relaxation sweeps, histogram + fold
def tile_run (t : UInt32) (e : Nat) : UInt32 :=
  let ox := (t &&& 255) <<< (6 : UInt32)
  let oz := (t >>> (8 : UInt32)) <<< (6 : UInt32)
  let h := Array.replicate 4096 (0 : UInt32)
  let h := tile_fill ox oz h
  let h := tile_smooth e h
  tile_hist h (t + 1)

def batch_run : Nat → UInt32 → Nat → UInt32
  | 0, t, e => tile_run t e
  | d + 1, t, e =>
      let a := batch_run d t e
      let b := batch_run d (t + (1 <<< UInt32.ofNat d)) e
      a + b

def main : IO Unit :=
  IO.println (batch_run 16 0 5)
