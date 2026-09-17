# variable-match twin of check_capture_price_twin_001: a binder spent
# once in EACH arm of a variable match measures at the branch join
# (pointwise max), so the affine program accepts; the bystander
# hypothesis h rides dead and costs nothing.
# ported from bend3: bend statement-lets cannot precede a match, so k
# spends inside the arms
type Nd is Data:
  Zd{}
  Sd{p: Nd}

law use:
  for m: Nd
  for h: {m == Zd{} : Nd}
  for k: Nd -> Nd
  Nd

def use(m, h, k):
  match m:
    case Zd{}:
      k(Zd{})
    case Sd{p}:
      k(Sd{p})

law main:
  Nd

def main():
  Zd{}

#|Zd{}
