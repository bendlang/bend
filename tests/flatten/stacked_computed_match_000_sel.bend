# two COMPUTED scrutinees: bend's match takes bare scrutinees, so the
# computed values feed a helper's pattern columns
# ported from bend3: the numeric domain becomes a ctor word, literal
# arm values become ctors
type W is Data:
  WZ{}
  WS{p: W}

type Nt is Data:
  Zn{}
  Sn{p: Nt}

type R is Data:
  K0{}
  K1{}
  K2{}
  K3{}

law nat:
  for x: W
  Nt

def nat(x):
  match x:
    case WZ{}:
      Zn{}
    case k:
      Sn{Zn{}}

law main:
  for a: Nt
  for b: Nt
  R

def main(a, b):
  match a, b:
    case Zn{}, Zn{}:
      K0{}
    case Zn{}, Sn{p}:
      K1{}
    case Sn{p}, Zn{}:
      K2{}
    case Sn{p}, Sn{q}:
      K3{}

#|\{Zn: \{Zn: K0{}; Sn: (p => K1{})}; Sn: (p => \{Zn: K2{}; Sn: (q => K3{})})}
