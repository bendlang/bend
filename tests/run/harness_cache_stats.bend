# gates/test.ts compares repeated C/JS emissions and actual values with
# fresh baselines, before and after normalization. The retained compiler
# probe count must match the fresh baseline too, even if bytes agree.
import Base

law flip:
  for c: Cmp
  Cmp

def flip(c):
  match c:
    case LT{}:
      GT{}
    case EQ{}:
      EQ{}
    case GT{}:
      LT{}

def Cmp.text(c: Cmp) -> String:
  match c:
    case LT{}:
      "LT{}"
    case EQ{}:
      "EQ{}"
    case GT{}:
      "GT{}"

law main:
  IO(Unit)

def main():
  IO.print(Cmp.text(flip(flip(LT{}))))

#|LT{}
