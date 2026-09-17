# an arm's error page shows the leaf context: n, the hypothesis h,
# the worker's scrutinee m, then the field p
# ported from bend3: the decision rides a worker def and never
# specializes hypotheses, so h stays at the frozen {dbl(n) == MZ{}}
# spelling (in bend3 it showed the specialized {S{p} == 0n})
import Base
type MNat is Data:
  MZ{}
  MS{p: MNat}

law dbl:
  for n: MNat
  MNat

def dbl(n):
  match n:
    case MZ{}:
      MZ{}
    case MS{p}:
      MS{MS{dbl(p)}}

law use:
  for n: MNat
  for h: {dbl(n) == MZ{} : MNat}
  U32

law use.at:
  for -n: MNat
  for  h: {dbl(n) == MZ{} : MNat}
  for  m: MNat
  U32

def use.at(n, h, m):
  match m:
    case MZ{}:
      b = h
      0
    case MS{p}:
      p

def use(n, h):
  use.at(n, h, dbl(n))

#|Error:
#|- expected : U32
#|- observed : MNat
#|Context:
#|- n : MNat
#|- h : {dbl(n) == MZ{} : MNat}
#|- p : MNat
#|Location: use.at
#|38 |     case MS{p}:
#|39>|       p
#|40 | 
#|exit 1
