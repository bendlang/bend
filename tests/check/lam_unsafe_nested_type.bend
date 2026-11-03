# as lam_plus_nested_type, in an @unsafe def: a + binder only has to be a type
# there, and the goal's domain already is one
type Tag<-f: Quant -> Quant> is Data:
  T{}

def tag(f: Quant -> Quant) -> Tag<f>:
  T{}

def app(f: Quant -> Quant, g: Tag<f> -> Quant) -> Quant:
  &1

@unsafe
def main() -> Quant:
  app(a0 => app(a1 => app(a2 => app(a3 => app(a4 => app(a5 => app(a6 => app(a7 => app(a8 => app(a9 => app(a10 => app(a11 => app(a12 => app(a13 => app(a14 => app(a15 => app(a16 => app(a17 => app(a18 => app(a19 => app(a20 => app(a21 => app(a22 => app(a23 => app(a24 => app(a25 => app(a26 => app(a27 => app(a28 => app(a29 => &1, +t29 => &1), +t28 => &1), +t27 => &1), +t26 => &1), +t25 => &1), +t24 => &1), +t23 => &1), +t22 => &1), +t21 => &1), +t20 => &1), +t19 => &1), +t18 => &1), +t17 => &1), +t16 => &1), +t15 => &1), +t14 => &1), +t13 => &1), +t12 => &1), +t11 => &1), +t10 => &1), +t9 => &1), +t8 => &1), +t7 => &1), +t6 => &1), +t5 => &1), +t4 => &1), +t3 => &1), +t2 => &1), +t1 => &1), +t0 => &1)

#|&1
