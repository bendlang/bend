# bend3's splice law made do-binds agree with their desugaring at
# generic pair yields; bend's do reads the bind types as spelled, and
# the nested-pair yields ride Result whole (the ++ half was Cat over
# a pair-element List: bend's ++ is String.append, pending wider
# ruling, so that half stays out)
import Base

law f8:
  Result<&2, &1, U32, F32 & Unit>

def f8():
  Done{(1.5, Unit{})}

law g8:
  Result<&2, &1, U32, U32 & (F32 & Unit)>

def g8():
  Done{(7, (2.5, Unit{}))}

law prog:
  Result<&2, &1, U32, U32>

def prog():
  do Result<&2, &1, U32, U32>:
    x : F32 & Unit <- f8()
    y : U32 & (F32 & Unit) <- g8()
    return 0

law unwrap:
  for r: Result<&2, &1, U32, U32>
  U32

def unwrap(r):
  match r:
    case Done{v}:
      v
    case Fail{x}:
      x

law main.out:
  Nat

def main.out():
  U32.to_nat(unwrap(prog()))

law main:
  IO(Unit)

def main():
  IO.print(String.append(Nat.show(main.out()), "n"))

#|0n
