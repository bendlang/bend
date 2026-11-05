# as let_dependent_type, for + binders: the family's signature says Tag<..> is
# Data, so check-let does not check its arguments again. Twenty deep, where the
# kernel, which still checks them, gives its verdict in about 3 s: the 30-deep
# lam_plus_nested_type guards the shared term_check_bound
type Tag<-f: Quant -> Quant> is Data:
  T{}

def tag(f: Quant -> Quant) -> Tag<f>:
  T{}

def main() -> Quant:
  +x = tag(a0 => (+y1 = tag(a1 => (+y2 = tag(a2 => (+y3 = tag(a3 => (+y4 = tag(a4 => (+y5 = tag(a5 => (+y6 = tag(a6 => (+y7 = tag(a7 => (+y8 = tag(a8 => (+y9 = tag(a9 => (+y10 = tag(a10 => (+y11 = tag(a11 => (+y12 = tag(a12 => (+y13 = tag(a13 => (+y14 = tag(a14 => (+y15 = tag(a15 => (+y16 = tag(a16 => (+y17 = tag(a17 => (+y18 = tag(a18 => (+y19 = tag(a19 => &1); &1)); &1)); &1)); &1)); &1)); &1)); &1)); &1)); &1)); &1)); &1)); &1)); &1)); &1)); &1)); &1)); &1)); &1)); &1));
  &1

#|&1
