# an equation is Data, so a + binder at one does not check its sides again. Ten
# deep: 2^10-fold work if it does, and the kernel, which still checks them,
# gives its verdict in about 2 s
type Tag<-f: Quant -> Quant> is Data:
  T{}

def tag(f: Quant -> Quant) -> Tag<f>:
  T{}

def pf(f: Quant -> Quant) -> {tag(f) == tag(f) : Tag<f>}:
  {==}

def main() -> Quant:
  +x = pf(a0 => (+y1 = pf(a1 => (+y2 = pf(a2 => (+y3 = pf(a3 => (+y4 = pf(a4 => (+y5 = pf(a5 => (+y6 = pf(a6 => (+y7 = pf(a7 => (+y8 = pf(a8 => (+y9 = pf(a9 => &1); &1)); &1)); &1)); &1)); &1)); &1)); &1)); &1)); &1));
  &1

#|&1
