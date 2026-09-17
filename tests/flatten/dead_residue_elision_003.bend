# bend3 pinned out-of-order nested matches (the reversed column order
# leaves a row riding a dead, elided residue); bend BANS out-of-order
# matches by ruling, so the same shape pins bend's own refusal
type Bl is Data:
  T{}
  F{}

type Nt is Data:
  Z{}
  S{p: Nt}

type R is Data:
  K1{}
  K2{}
  K3{}

law main:
  for x: Nt
  for y: Bl
  R

def main(x, y):
  match y:
    case T{}:
      match x:
        case Z{}:
          K1{}
        case S{p}:
          K3{}
    case F{}:
      K2{}

#|Error:
#|- message  : match scrutinees in binder order (this variable is unbound, consumed, or out of order: reorder the match)
#|Location:
#|24 |     case T{}:
#|25>|       match x:
#|26 |         case Z{}:
#|exit 1
