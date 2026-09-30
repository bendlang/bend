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

#|SOME PROOFS FAIL
#|Error:
#|- message  : a match in binder order (a can't be matched after a match on a later binder or after a local statement: match a earlier, or give the value its own def)
#|Location:
#|15 | def main(a):
#|16>|   match a, a:
#|   |            ^
#|17 |     case Z{}, x:
#|exit 1
