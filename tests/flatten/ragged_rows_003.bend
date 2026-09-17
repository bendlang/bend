# ragged nested matches: a default arm closes its level without touching
# the later columns (dominance), rigid rows below a default drive their
# own subgroups -- the flow shape, pinned structurally
# ported from bend3: numeric columns become ctor columns (W), literal
# arm values become ctors (bend has no number patterns)
type W is Data:
  WZ{}
  WS{p: W}

type Nat is Data:
  Z{}
  S{p: Nat}

type R is Data:
  K100{}
  K200{}
  K300{}

law main:
  for d: W
  for m: W
  for n: Nat
  R

def main(d, m, n):
  match d:
    case WZ{}:
      K100{}
    case WS{d}:
      match m:
        case WZ{}:
          match n:
            case S{p}:
              main(d, WZ{}, p)
            case n:
              K200{}
        case m:
          K300{}

#|\{WZ: (m => n => K100{}); WS: (d => \{WZ: \{S: (p => main(d, WZ{}, p)); (n => K200{})}; (m => n => K300{})})}
