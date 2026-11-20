# a family whose kind reads its argument, at an argument that makes it Data:
# the + binder takes the full check, which accepts it
type K<-g: Quant> is Kind(g):
  KK{}

def ky(g: Quant) -> K<g>:
  KK{}

def main() -> Quant:
  +x = ky(&2);
  &1

#|&1
