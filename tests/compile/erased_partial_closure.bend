# a ref-partial closure with an erased remaining param: dynamic callers
# feed every source arg (erased included) through the stored value
# ported from bend3
import Base

law kf.go:
  for -n: U32
  for  x: U32
  U32

def kf.go(n, x):
  x

law kf:
  @-n: U32 -> U32 -> U32

def kf():
  kf.go

type BoxK is Type:
  MkBoxK{f: @-n: U32 -> U32 -> U32}

law use:
  for b: BoxK
  U32

def use(b):
  match b:
    case MkBoxK{f}:
      f(9, 3)

law main.out:
  U32

def main.out():
  use(MkBoxK{kf})

law main:
  IO(Unit)

def main():
  IO.print(U32.show(main.out()))

#|3
