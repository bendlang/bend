type Nat is Data:
  Z{}
  S{p: Nat}

type R is Data:
  A{x: Nat, y: Nat}

law main:
  for a: Nat
  for b: Nat
  R

def main(a, b):
  A{a,b}

#|a => b => A{a, b}
