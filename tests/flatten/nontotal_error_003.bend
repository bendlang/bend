# error quality: a non-exhaustive match names the missing constructor.
# ported from bend3
type Ne3 is Data:
  Ze3{}
  Se3{p: Ne3}

law pred:
  for n: Ne3
  Ne3

def pred(n):
  match n:
    case Se3{p}:
      p

law main:
  Ne3

def main(): pred(Se3{Ze3{}})

#|Error:
#|- expected : cases for Ze3
#|- observed : \{}
#|Location: pred
#|11 | def pred(n):
#|12>|   match n:
#|13 |     case Se3{p}:
#|exit 1
