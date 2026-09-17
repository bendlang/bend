# word-switch ladder, complete: the IH rewrite closes the miss arm;
# the checked proof's value displays as the REF chain (bend's show
# refolds a stuck match to its ref -- bend3's --eval case-tree literal
# has no bend face; main's eta form replaces the --eval lane)
# ported from bend3: U32 switch -> Nat; rewrite takes its motive
import Base
type MN is Data:
  Z{}
  S{p: MN}

law ones:
  for n: Nat
  MN

def ones(n):
  match n:
    case 0n:
      Z{}
    case 1n+n:
      S{ones(n)}

law twos:
  for n: Nat
  MN

def twos(n):
  match n:
    case 0n:
      Z{}
    case 1n+n:
      S{twos(n)}

law ones_twos:
  for n: Nat
  {ones(n) == twos(n) : MN}

def ones_twos(n):
  match n:
    case 0n:
      {==}
    case 1n+n:
      %ones_twos(n) : {S{ones(n)} == S{_} : MN}
      {==}

law main:
  @n: Nat -> {ones(n) == twos(n) : MN}

def main():
  n => ones_twos(n)

#|n => ones_twos(n)
