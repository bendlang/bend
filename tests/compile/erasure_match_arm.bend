# runtime erasure at a binderless lambda-match arm: the erased ctor
# field rides into the arm head and drops against the callee's erased
# param
# ported from bend3: the spin counter walks a Nat, its U32 image rebuilt
import Base

type Ev is Data:
  MkEv{-t: U32, v: Nat}

law spinr:
  for +n  : Nat
  for acc : U32
  U32

def spinr(n, acc):
  match n:
    case 0n:
      acc
    case 1n+p:
      spinr(p, U32.add(acc, U32.add(1, U32.from_nat(p))))

law uset:
  for -t: U32
  for  v: Nat
  U32

def uset(t, v):
  spinr(v, 1)

law f:
  Ev -> U32

def f():
  \{MkEv: uset}

law main.out:
  U32

def main.out():
  U32.add(f(MkEv{7, 3n}), f(MkEv{1, 2n}))

law main:
  IO(Unit)

def main():
  IO.print(U32.show(main.out()))

#|11
