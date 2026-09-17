# bend3's named-column alias `match (k = x)` names a column over the
# bare binder; bend's match takes bare scrutinees only, so the alias
# form pins bend's own refusal
# ported from bend3: the numeric column becomes a ctor column
type W is Data:
  Z{}
  S{p: W}

law main:
  for x: W
  W

def main(x):
  match (k = x):
    case Z{}:
      Z{}
    case S{p}:
      x

#|Error:
#|- expected : a term
#|- observed : ')'
#|Location:
#|13 | def main(x):
#|14>|   match (k = x):
#|15 |     case Z{}:
#|exit 1
