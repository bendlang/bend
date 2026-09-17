# bend3 pinned match blocks as terms; bend lets inside a match arm,
# and the let's bare-constructor value cannot infer, so the spelling
# pins that annotation demand (y = {S{x} : Nt} is the idiom)
type Nt is Data:
  Z{}
  S{p: Nt}

type Bl is Data:
  T{}
  F{}

law main:
  for x: Nt
  for b: Bl
  Nt

def main(x, b):
  match b:
    case T{}:
      y = S{x}
      y
    case F{}:
      y = S{x}
      S{y}

#|Error:
#|- expected : an annotated term (cannot infer)
#|- observed : S{x}
#|Context:
#|- x : Nt
#|Location: main
#|19 |     case T{}:
#|20>|       y = S{x}
#|21 |       y
#|exit 1
