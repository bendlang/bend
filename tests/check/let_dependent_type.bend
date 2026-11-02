# a let's type can hold its own value's argument: tag(f) : Tag<f>, so x :
# Tag<q => ..>. check-let checks that type's kind only where it can fail, as
# the kernel's let, so each lambda checks once. these lets are thirty deep:
# linear here, 2^30 checks if the kind check returns (#1940), far past the
# gates' 30 s cap. a shadowed q and an erased binder whose value uses an
# erased parameter check the same way
type Tag<-f: Quant -> Quant> is Data:
  T{}

def tag(f: Quant -> Quant) -> Tag<f>:
  T{}

def nest() -> Quant:
  x = tag(a0 => (y1 = tag(a1 => (y2 = tag(a2 => (y3 = tag(a3 => (y4 = tag(a4 => (y5 = tag(a5 => (y6 = tag(a6 => (y7 = tag(a7 => (y8 = tag(a8 => (y9 = tag(a9 => (y10 = tag(a10 => (y11 = tag(a11 => (y12 = tag(a12 => (y13 = tag(a13 => (y14 = tag(a14 => (y15 = tag(a15 => (y16 = tag(a16 => (y17 = tag(a17 => (y18 = tag(a18 => (y19 = tag(a19 => (y20 = tag(a20 => (y21 = tag(a21 => (y22 = tag(a22 => (y23 = tag(a23 => (y24 = tag(a24 => (y25 = tag(a25 => (y26 = tag(a26 => (y27 = tag(a27 => (y28 = tag(a28 => (y29 = tag(a29 => &1); &1)); &1)); &1)); &1)); &1)); &1)); &1)); &1)); &1)); &1)); &1)); &1)); &1)); &1)); &1)); &1)); &1)); &1)); &1)); &1)); &1)); &1)); &1)); &1)); &1)); &1)); &1)); &1)); &1));
  &1

def shadow() -> Quant:
  x = tag(q => (y = tag(q => q); q));
  &1

def erased(-k: Quant) -> Quant:
  -x = tag(q => k);
  &1

def main() -> Quant:
  erased(nest())

#|&1
