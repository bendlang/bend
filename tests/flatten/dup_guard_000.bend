# bend3's plain dup guard scrutinized the same var twice in one group
# (words contract freely there); bend's core is affine, so the same
# spelling pins bend's own refusal
# ported from bend3: the numeric column becomes a ctor column
type W is Data:
  Z{}
  S{p: W}

law main:
  for a: W
  W

def main(a):
  match a, a:
    case Z{}, x:
      x
    case k, x:
      k

#|SOME PROOFS FAIL
#|Error:
#|- message  : a match on a parameter or field in binder order (this name is bound before one matched earlier, or is a def or a consumed binder: match it first, or give the value its own def)
#|Location:
#|13 | def main(a):
#|14>|   match a, a:
#|   |            ^
#|15 |     case Z{}, x:
#|exit 1
