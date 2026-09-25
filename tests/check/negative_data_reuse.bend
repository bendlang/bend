# the classic negative-datatype loop needs the function field twice
# (omega(L{f}) = f(L{f})), which linearity rejects: f is Lone.
# ported from bend3
import Base

type Tn is Type:
  Ln{f: Tn -> Tn}
  Vn{n: U32}

law omega:
  for t: Tn
  Tn

def omega(t):
  match t:
    case Ln{f}:
      f(Ln{f})
    case Vn{n}:
      Vn{n}

law main:
  Tn

def main(): omega(Ln{t => t})

#|Error:
#|- expected : f
#|- observed : f (consumed more than once)
#|Location: omega
#|15 |   match t:
#|16>|     case Ln{f}:
#|   |             ^
#|17 |       f(Ln{f})
#|exit 1
