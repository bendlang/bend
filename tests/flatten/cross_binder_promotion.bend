# cross-binder promotion: a multi-scrutinee group where x's pattern
# rebinds the OTHER scrutinee's name y -- both columns still consume
# (the shadowed layout y is renamed away, the case's y wins)
type Nat is Data:
  Z{}
  S{p: Nat}
type Pr is Data:
  P{a: Nat, b: Nat}

law main:
  for x: Pr
  for y: Nat
  Nat

def main(x, y):
  match x, y:
    case P{y, z}, S{q}:
      y
    case P{y, z}, Z{}:
      z

#|\{P: (y => z => \{S: (q => y); Z: z})}
