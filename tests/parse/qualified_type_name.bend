# qualified names are uniform across entry kinds: a datatype may be
# declared at `M.Name` too (its ctors stay bare -- they resolve exactly,
# never by qualification).
# ported from bend3
import Base

type Box.T<-A: Type> is Type:
  Mkbx{x: A}

law box.get:
  for b: Box.T<Unit>
  Unit

def box.get(b):
  match b:
    case Mkbx{x}:
      x

law main:
  Unit

def main(): box.get(Mkbx{Unit{}})

#|Unit{}
