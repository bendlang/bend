# regression (AUDIT 4b), repurposed for the banned form: a local, then
# a match on it, is a lambda-match application in disguise -- the
# flatten refuses it loud (give the match its own def, where the
# scrutinee is a parameter)
import Base

type Bit is Data:
  On{}
  Off{}

law flip:
  for v: Bit
  Bit

def flip(v):
  x = v
  match x:
    case On{}:
      Off{}
    case Off{}:
      On{}

law main:
  Bit

def main():
  flip(On{})

#|Error:
#|- message  : a parameter or field scrutinee (a match cannot scrutinize a local binder: give it its own def)
#|Location:
#|15 | def flip(v):
#|16>|   x = v
#|17 |   match x:
#|exit 1
