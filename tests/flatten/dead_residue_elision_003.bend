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

#|SOME PROOFS FAIL
#|Error:
#|- message  : a match on a parameter or field in binder order (this name is bound before one matched earlier, or is a def or a consumed binder: match it first, or give the value its own def)
#|Location:
#|24 |     case T{}:
#|25>|       match x:
#|   |             ^
#|26 |         case Z{}:
#|exit 1
