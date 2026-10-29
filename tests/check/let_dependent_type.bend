# a let's type can hold its own value's argument: tag(f) : Tag<f>, so x :
# Tag<q => ..>. check-let checks that type's kind at a + binder only, as
# the kernel's let, so each lambda checks once and these ten nested lets
# check in linear time, not 2^10 (#1940); a shadowed q and an erased
# binder whose value uses an erased parameter check the same way
type Tag<-f: Quant -> Quant> is Data:
  T{}

def tag(f: Quant -> Quant) -> Tag<f>:
  T{}

def nest() -> Quant:
  x = tag(q => (y1 = tag(r => (y2 = tag(s => (y3 = tag(t => (y4 = tag(u => (y5 = tag(v => (y6 = tag(w => (y7 = tag(x => (y8 = tag(y => (y9 = tag(z => &1); &1)); &1)); &1)); &1)); &1)); &1)); &1)); &1)); &1));
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
