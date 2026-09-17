type Nat is Data:
  Z{}
  S{p: Nat}

type R is Data:
  A{a: Nat, b: Nat}
  B{a: Nat}

law main:
  for a: Nat
  for b: Nat
  R

def main(a, b):
  match a, b:
    case a, S{b}:
      A{a,b}
    case a, Z{}:
      B{a}

#|a => \{S: (b => A{a, b}); Z: B{a}}
