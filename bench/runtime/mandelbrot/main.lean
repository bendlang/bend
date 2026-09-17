-- Native Lean translation of main.bend: histogram-equalized
-- escape-time render, 4096x4096, signed 8.8 fixed point, ITERS
-- branchless iterations per pixel (z freezes at escape).
def ITERS : UInt32 := 51
def WIDTH : UInt32 := 4096

def value_select (t x y : UInt32) : UInt32 :=
  if t = 0 then x else y

-- arithmetic shift right by 8 over two's-complement u32
def word_asr8 (v : UInt32) : UInt32 :=
  (v >>> 8) ||| value_select (v >>> 31) 0 4278190080

-- ITERS branchless escape-time iterations: z steps while esc == 0 and
-- freezes after, it counts the pre-escape iterations
def pixel_iterate : Nat -> UInt32 -> UInt32 -> UInt32 -> UInt32 -> UInt32 -> UInt32 -> UInt32
  | 0, _, _, _, _, _, it => it
  | n + 1, cr, ci, zr, zi, esc, it =>
    let r2 := word_asr8 (zr * zr)
    let i2 := word_asr8 (zi * zi)
    let e2 := esc ||| (if r2 + i2 > 1024 then 1 else 0)
    let nzr := r2 - i2 + cr
    let nzi := word_asr8 (2 * (zr * zi)) + ci
    pixel_iterate n cr ci (value_select e2 nzr zr) (value_select e2 nzi zi) e2
      (it + (if e2 = 0 then 1 else 0))

-- one pixel: viewport [-2, 1) x [-1.5, 1.5) over the WIDTH^2 grid
def pixel_escape (id : UInt32) : UInt32 :=
  let cr := (id &&& (WIDTH - 1)) * 768 / WIDTH - 512
  let ci := (id / WIDTH) * 768 / WIDTH - 384
  pixel_iterate ITERS.toNat cr ci 0 0 0 0

-- escape time -> one of 8 buckets, knob-stable
def pixel_bucket (it : UInt32) : UInt32 :=
  let bq := it * 8 / ITERS
  value_select (if bq > 7 then 1 else 0) bq 7

def main : IO Unit := do
  let total := WIDTH * WIDTH
  let mut h : Array UInt32 := Array.replicate 8 0
  let mut i : UInt32 := 0
  for _ in [0:total.toNat] do
    let b := pixel_bucket (pixel_escape i)
    h := h.set! b.toNat (h[b.toNat]! + 1)
    i := i + 1
  let mut lut : Array UInt32 := Array.replicate 8 0
  let mut c : UInt32 := 0
  for k in [0:8] do
    c := c + h[k]!
    lut := lut.set! k c
  let cn := lut[7]!
  for k in [0:8] do
    lut := lut.set! k (lut[k]! * 255 / cn)
  let mut mix := lut[0]!
  for k in [1:8] do
    mix := mix * 2654435761 + lut[k]!
  let mut r : UInt32 := 0
  let mut j : UInt32 := 0
  for _ in [0:total.toNat] do
    let it := pixel_escape j
    let col := lut[(pixel_bucket it).toNat]!
    r := r + (col * (j * 2654435761 + 1) + it)
    j := j + 1
  IO.println (mix * 2654435761 + r)
