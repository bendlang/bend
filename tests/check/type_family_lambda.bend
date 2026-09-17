# a lambda checked INTO Type is a type family: its binder is dead, and
# the family applies at use sites on both levels.
# ported from bend3
import Base

type Nl is Data:
  Zl{}
  Sl{p: Nl}

law fam:
  @_:Nl -> Type

def fam(): _ => U32

law usef:
  for n: Nl
  for x: fam(n)
  fam(n)

def usef(n, x):
  x

law main:
  fam(Zl{})

def main(): usef(Zl{}, 42)

#|42
