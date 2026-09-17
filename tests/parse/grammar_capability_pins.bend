# grammar capability pins (a removed FORM must break this suite): the
# comma-separated multi-scrutinee match/case.
# ported from bend3: the &-fork let and infix operators are bend3-only,
# so this port keeps the multi-scrutinee pin and spells arithmetic as
# ctor values
type Nn5 is Data:
  Zz5{}
  Ss5{p: Nn5}

law tab:
  for a: Nn5
  for b: Nn5
  Nn5

def tab(a, b):
  match a, b:
    case Zz5{}, Zz5{}:
      Zz5{}
    case Zz5{}, Ss5{q}:
      Ss5{Zz5{}}
    case Ss5{p}, Zz5{}:
      Ss5{Ss5{Zz5{}}}
    case Ss5{p}, Ss5{q}:
      Ss5{Ss5{Ss5{Zz5{}}}}

law main:
  Nn5

def main():
  tab(Ss5{Zz5{}}, Zz5{})

#|Ss5{Ss5{Zz5{}}}
