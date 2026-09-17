# three scrutinees mixing pattern columns and a COMPUTED middle; bend's
# match takes bare scrutinees, so the computed value feeds a helper's
# var column and the ctor rows flatten there
# ported from bend3: literal arm values become ctors
type Bit is Data:
  O{}
  I{}

type R is Data:
  K0{}
  K1{}
  K2{}
  K3{}
  K4{}
  K5{}
  K6{}
  K7{}

law main:
  for b: Bit
  Bit

def main(b):
  match b:
    case O{}:
      I{}
    case I{}:
      O{}

law sel:
  for a  : Bit
  for fb : Bit
  for c  : Bit
  R

def sel(a, fb, c):
  match a, fb, c:
    case O{}, O{}, O{}:
      K0{}
    case O{}, O{}, I{}:
      K1{}
    case O{}, I{}, O{}:
      K2{}
    case O{}, I{}, I{}:
      K3{}
    case I{}, O{}, O{}:
      K4{}
    case I{}, O{}, I{}:
      K5{}
    case I{}, I{}, O{}:
      K6{}
    case I{}, I{}, I{}:
      K7{}

#|\{O: I{}; I: O{}}
