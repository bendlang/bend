# bend3's ADT dup guard scrutinized the same var twice in one group;
# bend's core is affine, so the same spelling pins bend's own refusal
type Nat is Data:
  Z{}
  S{p: Nat}

type R is Data:
  R0{}
  R1{}

law main:
  for a: Nat
  R

def main(a):
  match a, a:
    case Z{}, x:
      R0{}
    case S{p}, x:
      R1{}

#|Error:
#|- message  : a match on a parameter or field (this name is a def or a consumed binder: give the value its own def)
#|Location:
#|15 | def main(a):
#|16>|   match a, a:
#|17 |     case Z{}, x:
#|exit 1
