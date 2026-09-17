# hypothesis/goal agreement through both scrutinee shapes: a variable
# match specializes hypothesis and goal together, and a computed
# scrutinee, split behind its own def, leaves both frozen at the call
# spelling -- in each twin the arm's h still meets the goal, so both
# proofs accept.
# ported from bend3: bend3 specialized computed hypotheses per arm;
# bend freezes the split-out worker's goal, and the twins accept
type Nf is Data:
  Zf{}
  Sf{p: Nf}

law dbl:
  for n: Nf
  Nf

def dbl(n):
  match n:
    case Zf{}:
      Zf{}
    case Sf{p}:
      Sf{Sf{dbl(p)}}

law p_var:
  for m: Nf
  for h: {m == Zf{} : Nf}
  {m == Zf{} : Nf}

def p_var(m, h):
  match m:
    case Zf{}:
      h
    case Sf{p}:
      h

law p_comp.go:
  for -n: Nf
  for  h: {dbl(n) == Zf{} : Nf}
  for  w: Nf
  {dbl(n) == Zf{} : Nf}

def p_comp.go(n, h, w):
  match w:
    case Zf{}:
      h
    case Sf{p}:
      h

law p_comp:
  for n: Nf
  for h: {dbl(n) == Zf{} : Nf}
  {dbl(n) == Zf{} : Nf}

def p_comp(n, h):
  p_comp.go(n, h, dbl(n))

law main:
  Nf

def main():
  Zf{}

#|Zf{}
