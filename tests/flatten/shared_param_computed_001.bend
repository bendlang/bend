# bend3 pinned `x = v; match x` (a let-var match is a computed match);
# bend bans it: matching a local binder is a lambda-match application,
# so the flattener rejects with a pointer to the worker-def port
type Nt is Data:
  Z{}
  S{p: Nt}

law main:
  for v: Nt
  Nt

def main(v):
  x = v
  match x:
    case Z{}:
      Z{}
    case S{p}:
      p

#|Error:
#|- message  : a parameter or field scrutinee (a match cannot scrutinize a local binder: give it its own def)
#|Location:
#|12 | def main(v):
#|13>|   x = v
#|   |   ^
#|14 |   match x:
#|exit 1
