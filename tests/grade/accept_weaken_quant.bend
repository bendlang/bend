# a quantity whose type only evaluates to Quant still weakens: a reusable
# Box<&2> fits an affine Box<&1>
def Q() -> Type:
  Quant

type Box<-q: Q()> is Kind(q):
  Box{}

def weaken(x: Box<&2>) -> Box<&1>:
  x

def main() -> Box<&1>:
  weaken(Box{})

#|Box{}
