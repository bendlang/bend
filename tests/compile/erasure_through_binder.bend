# runtime erasure through binders: an application whose head is a
# variable (a let, an alias, a def parameter) drops its erased
# argument -- value, Type, or proof -- at the call site; a bare
# generic ref feeds Type through a dynamic apply; a dead let of proof
# type is never executed
# ported from bend3 (Nat literals for the equality's endpoints)
import Base

type BoxT is Type:
  MkBoxT{f: @-x: Type -> U32}

law fst2:
  for -A: Type
  for  x: U32
  for  y: U32
  U32

def fst2(A, x, y):
  x

law prf:
  {0n == 0n : Nat}

def prf():
  {==}

law unbox:
  for b: BoxT
  U32

def unbox(b):
  match b:
    case MkBoxT{f}:
      f(U32)

law main.out:
  U32

def main.out():
  g = {x => 11 : @-x: U32 -> U32}
  h = g
  t = {x => 2 : @-x: Type -> U32}
  c = {y => z => z : @-y: {0n == 0n : Nat} -> @z: U32 -> U32}
  e = prf()
  s = fst2
  U32.add(U32.add(U32.add(U32.add(h(987654321), t(U32)), c({==}, 4)), unbox(MkBoxT{x => 8})), s(U32, 16, 9))

law main:
  IO(Unit)

def main():
  IO.print(U32.show(main.out()))

#|41
