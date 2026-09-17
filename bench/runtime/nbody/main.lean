-- Native Lean translation of main.bend: chaotic three-body
-- ensemble, Float32, Plummer-softened, symplectic Euler.
def SY : Nat := 17
def STEPS : Nat := 300

def word_prng (x : UInt32) : UInt32 :=
  let b := x ^^^ (x <<< 13)
  let d := b ^^^ (b >>> 17)
  d ^^^ (d <<< 5)

-- f32_to_u32: truncate toward zero; NaN, negative, or >= 2^32 -> 0
def float_word (v : Float32) : UInt32 :=
  if v.isNaN || v < 1.0 || v >= 4294967296.0 then 0 else v.toUInt32

def seed_hash (sd k : UInt32) : UInt32 :=
  word_prng ((sd * 12 + k) * 2654435761)

def seed_unit (sd k : UInt32) : Float32 :=
  (seed_hash sd k &&& 65535).toNat.toFloat32 / 32768.0 - 1.0

def seed_mass (sd k : UInt32) : Float32 :=
  (seed_hash sd k &&& 65535).toNat.toFloat32 / 65536.0 + 0.5

-- ST integration steps over one system's 21 f32 state registers
-- (tail recursion keeps Float32 unboxed), then digest (cs, eb)
def loop3 (s : Nat) (x0 y0 z0 x1 y1 z1 x2 y2 z2 vx0 vy0 vz0 vx1 vy1 vz1 vx2 vy2 vz2 m0 m1 m2 : Float32) : UInt32 × UInt32 :=
  match s with
  | 0 =>
    let s0 := vx0 * vx0 + (vy0 * vy0 + vz0 * vz0)
    let s1 := vx1 * vx1 + (vy1 * vy1 + vz1 * vz1)
    let s2 := vx2 * vx2 + (vy2 * vy2 + vz2 * vz2)
    let k0 := ((0.5 : Float32) * m0) * s0
    let k1 := ((0.5 : Float32) * m1) * s1
    let k2 := ((0.5 : Float32) * m2) * s2
    let ke := k0 + (k1 + k2)
    let ax := x1 - x0
    let ay := y1 - y0
    let az := z1 - z0
    let da := (ax * ax + (ay * ay + az * az)) + 0.05
    let bx := x2 - x0
    let by' := y2 - y0
    let bz := z2 - z0
    let db := (bx * bx + (by' * by' + bz * bz)) + 0.05
    let cx := x2 - x1
    let cy := y2 - y1
    let cz := z2 - z1
    let dc := (cx * cx + (cy * cy + cz * cz)) + 0.05
    let pa := (m0 * m1) / Float32.sqrt da
    let pb := (m0 * m2) / Float32.sqrt db
    let pc := (m1 * m2) / Float32.sqrt dc
    let pe := pa + (pb + pc)
    let e := ke - pe
    let nb := float_word (0.0 - e)
    let eb := if nb > 7 then 7 else nb
    let w0 := float_word ((x0 + 8.0) * 65536.0) * 31 + float_word ((y0 + 8.0) * 65536.0)
    let w1 := float_word ((x1 + 8.0) * 65536.0) * 31 + float_word ((y1 + 8.0) * 65536.0)
    let w2 := float_word ((x2 + 8.0) * 65536.0) * 31 + float_word ((y2 + 8.0) * 65536.0)
    let w3 := float_word ((z0 + 8.0) * 65536.0) * 31 + float_word ((z1 + 8.0) * 65536.0)
    let w4 := w0 * 2654435761 + w1
    let w5 := w4 * 2654435761 + w2
    let w6 := w5 * 2654435761 + w3
    let cs := w6 * 2654435761 + float_word ((z2 + 8.0) * 65536.0)
    (cs, eb)
  | s + 1 =>
    let ax := x1 - x0
    let ay := y1 - y0
    let az := z1 - z0
    let da := (ax * ax + (ay * ay + az * az)) + 0.05
    let ia := 1.0 / Float32.sqrt da
    let i3a := (ia * ia) * ia
    let qax := ax * i3a
    let qay := ay * i3a
    let qaz := az * i3a
    let bx := x2 - x0
    let by' := y2 - y0
    let bz := z2 - z0
    let db := (bx * bx + (by' * by' + bz * bz)) + 0.05
    let ib := 1.0 / Float32.sqrt db
    let i3b := (ib * ib) * ib
    let qbx := bx * i3b
    let qby := by' * i3b
    let qbz := bz * i3b
    let cx := x2 - x1
    let cy := y2 - y1
    let cz := z2 - z1
    let dc := (cx * cx + (cy * cy + cz * cz)) + 0.05
    let ic := 1.0 / Float32.sqrt dc
    let i3c := (ic * ic) * ic
    let qcx := cx * i3c
    let qcy := cy * i3c
    let qcz := cz * i3c
    let nvx0 := vx0 + (qax * m1 + qbx * m2) * 0.001
    let nvy0 := vy0 + (qay * m1 + qby * m2) * 0.001
    let nvz0 := vz0 + (qaz * m1 + qbz * m2) * 0.001
    let nvx1 := vx1 + (qcx * m2 - qax * m0) * 0.001
    let nvy1 := vy1 + (qcy * m2 - qay * m0) * 0.001
    let nvz1 := vz1 + (qcz * m2 - qaz * m0) * 0.001
    let nvx2 := vx2 - (qbx * m0 + qcx * m1) * 0.001
    let nvy2 := vy2 - (qby * m0 + qcy * m1) * 0.001
    let nvz2 := vz2 - (qbz * m0 + qcz * m1) * 0.001
    loop3 s
      (x0 + nvx0 * 0.001) (y0 + nvy0 * 0.001) (z0 + nvz0 * 0.001)
      (x1 + nvx1 * 0.001) (y1 + nvy1 * 0.001) (z1 + nvz1 * 0.001)
      (x2 + nvx2 * 0.001) (y2 + nvy2 * 0.001) (z2 + nvz2 * 0.001)
      nvx0 nvy0 nvz0 nvx1 nvy1 nvz1 nvx2 nvy2 nvz2 m0 m1 m2

-- one random system: three seeded bodies, STEPS steps, digest (cs, eb)
def system_run (sd : UInt32) (st : Nat) : UInt32 × UInt32 :=
  let x0 := seed_unit sd 1
  let y0 := seed_unit sd 2
  let z0 := seed_unit sd 3
  let m0 := seed_mass sd 4
  let x1 := seed_unit sd 5
  let y1 := seed_unit sd 6
  let z1 := seed_unit sd 7
  let m1 := seed_mass sd 8
  let x2 := seed_unit sd 9
  let y2 := seed_unit sd 10
  let z2 := seed_unit sd 11
  let m2 := seed_mass sd 12
  loop3 st x0 y0 z0 x1 y1 z1 x2 y2 z2
    (y0 * 0.1) (0.0 - x0 * 0.1) 0.0
    (y1 * 0.1) (0.0 - x1 * 0.1) 0.0
    (y2 * 0.1) (0.0 - x2 * 0.1) 0.0
    m0 m1 m2

def main : IO Unit := do
  let count : Nat := 8 <<< SY
  let mut h : Array UInt32 := Array.replicate 8 0
  let mut sum : UInt32 := 0
  let mut sd : UInt32 := 0
  for _ in [0:count] do
    let (cs, eb) := system_run sd STEPS
    h := h.set! eb.toNat (h[eb.toNat]! + 1)
    sum := sum + cs * (sd * 2654435761 + 1)
    sd := sd + 1
  let mut g := h[0]!
  for k in [1:8] do
    g := g * 2654435761 + h[k]!
  IO.println (g * 2654435761 + sum)
