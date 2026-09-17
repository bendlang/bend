-- Native Lean twin of main.bend: recursive block matrix multiply over
-- quad-trees with a Freivalds verification pass. Same datatypes, algorithms
-- and wrapping-u32 numerics (UInt32 throughout; counters are Nat).
inductive Mat where
  | lf (v : UInt32)
  | qd (a b c d : Mat)

inductive Vec where
  | vl (v : UInt32)
  | vn (l r : Vec)

def mat_gen : Nat → UInt32 → Mat
  | 0, s => .lf (s % 100)
  | d + 1, s =>
      .qd (mat_gen d (s * 1664525 + 1)) (mat_gen d (s * 214013 + 3))
        (mat_gen d (s * 16843009 + 5)) (mat_gen d (s * 48271 + 7))

def vec_gen : Nat → UInt32 → Vec
  | 0, s => .vl (s * 2654435761 % 100 + 1)
  | d + 1, s =>
      .vn (vec_gen d (s * 1664525 + 1)) (vec_gen d (s * 214013 + 3))

def mat_add : Mat → Mat → Mat
  | .lf x, .lf y => .lf (x + y)
  | .lf _, .qd _ _ _ _ => .lf 0
  | .qd _ _ _ _, .lf _ => .lf 0
  | .qd a0 a1 a2 a3, .qd b0 b1 b2 b3 =>
      .qd (mat_add a0 b0) (mat_add a1 b1) (mat_add a2 b2) (mat_add a3 b3)

-- join of one mul burst: C_ij = P_ij + Q_ij
def mat_add4 (p0 q0 p1 q1 p2 q2 p3 q3 : Mat) : Mat :=
  .qd (mat_add p0 q0) (mat_add p1 q1) (mat_add p2 q2) (mat_add p3 q3)

-- each node spawns its whole 8-product burst, joined through mat_add4
def mat_mul : Mat → Mat → Mat
  | .lf x, .lf y => .lf (x * y)
  | .lf _, .qd _ _ _ _ => .lf 0
  | .qd _ _ _ _, .lf _ => .lf 0
  | .qd a0 a1 a2 a3, .qd b0 b1 b2 b3 =>
      mat_add4 (mat_mul a0 b0) (mat_mul a1 b2) (mat_mul a0 b1)
        (mat_mul a1 b3) (mat_mul a2 b0) (mat_mul a3 b2) (mat_mul a2 b1)
        (mat_mul a3 b3)

def vec_add : Vec → Vec → Vec
  | .vl a, .vl b => .vl (a + b)
  | .vl _, .vn _ _ => .vl 0
  | .vn _ _, .vl _ => .vl 0
  | .vn a b, .vn c d => .vn (vec_add a c) (vec_add b d)

-- join of one mvm burst
def vec_add2 (t0 t1 t2 t3 : Vec) : Vec :=
  .vn (vec_add t0 t1) (vec_add t2 t3)

-- [[a,b],[c,d]] * (l,h) = (a*l + b*h, c*l + d*h)
def mat_vec_mul : Mat → Vec → Vec
  | .lf x, .vl y => .vl (x * y)
  | .lf _, .vn _ _ => .vl 0
  | .qd _ _ _ _, .vl _ => .vl 0
  | .qd a b c d, .vn l h =>
      vec_add2 (mat_vec_mul a l) (mat_vec_mul b h) (mat_vec_mul c l)
        (mat_vec_mul d h)

def mat_cksum : Mat → UInt32
  | .lf x => x
  | .qd a b c d => mat_cksum a + mat_cksum b + mat_cksum c + mat_cksum d

-- or-fold of elementwise xor: 0 iff the vectors are identical
def vec_dif : Vec → Vec → UInt32
  | .vl a, .vl b => a ^^^ b
  | .vl _, .vn _ _ => 1
  | .vn _ _, .vl _ => 1
  | .vn a b, .vn c d => vec_dif a c ||| vec_dif b d

-- one round: generate A, B, r; C = A*B; Freivalds-verify C*r == A*(B*r)
def round_run (d : Nat) (s : UInt32) : UInt32 :=
  let a := mat_gen d (s + 1)
  let b := mat_gen d (s + 2)
  let r := vec_gen d (s + 3)
  let c := mat_mul a b
  let k := mat_cksum c
  let t1 := mat_vec_mul c r
  let u := mat_vec_mul b r
  let t2 := mat_vec_mul a u
  let v := vec_dif t1 t2
  (k ^^^ (s * 2654435761)) + (if v = 0 then 1 else 0)

-- batch over the round index space: round i runs on seed = hashed index
-- (u32 addition commutes, so the tail loop equals the Bend fork tree)
def batch_run (nchain : Nat) (d : Nat) : UInt32 := Id.run do
  let mut acc : UInt32 := 0
  for i in [0:nchain] do
    acc := acc + round_run d (UInt32.ofNat i * 2654435761)
  return acc

def main : IO Unit :=
  IO.println (batch_run 384 7)
