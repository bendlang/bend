# an equality VALUE is Data: evidence is erased, so a + binder over an
# equation contracts and one proof feeds two result slots.
# ported from bend3: bend3's Data class contracted equations freely;
# bend core v1 pinned the refusal (no contraction); the grade kernel
# restores the contraction behind the explicit + binder
import Base

type Ns is Data:
  Zs{}
  Ss{p: Ns}

law dup_e:
  for  a: Ns
  for  b: Ns
  for +e: {a == b : Ns}
  {a == b : Ns} & {a == b : Ns}

def dup_e(a, b, e):
  (e, e)

law main:
  Ns

def main(): Zs{}

#|Zs{}
