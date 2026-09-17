# a dependent function as an ARGUMENT: f : @m:Nm -> P(m) checks against
# an opaque family P and instantiates at the call's index.
# ported from bend3
import Base

type Nm is Data:
  Zm{}
  Sm{p: Nm}

law Fam:
  for n: Nm
  Type

def Fam(n):
  match n:
    case Zm{}:
      U32
    case Sm{p}:
      Nm

law mk:
  for n: Nm
  Fam(n)

def mk(n):
  match n:
    case Zm{}:
      3
    case Sm{p}:
      Sm{p}

law apply:
  for -P: @_:Nm -> Type
  for  f: @m:Nm -> P(m)
  for  n: Nm
  P(n)

def apply(P, f, n):
  f(n)

law main:
  Fam(Zm{})

def main(): apply(Fam, mk, Zm{})

#|3
