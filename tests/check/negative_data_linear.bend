# negative datatypes are allowed (no positivity checker): a HOAS-style
# Term with a function field is harmless when used linearly, since
# closures can never satisfy a shared demand.
# ported from bend3
import Base

type Tm is Type:
  Lm{f: Tm -> Tm}
  Vm{n: U32}

law app9:
  for t: Tm
  for x: Tm
  Tm

def app9(t, x):
  match t:
    case Lm{f}:
      f(x)
    case Vm{n}:
      Vm{n}

law main:
  Tm

def main(): app9(Lm{x => x}, Vm{7})

#|Vm{7}
