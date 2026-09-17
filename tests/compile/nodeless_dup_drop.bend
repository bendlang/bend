# nullary and single-word ctors under contraction and discard: a value
# used twice, an unused binder, and a mixed-type boundary all compile
# ported from bend3: shares become +lets, the counter walks a Nat
import Base

type Dir is Data:
  Nn{}
  Ss{}

type Code is Data:
  Cc{v: U32}

type BoxB is Data:
  NilB{}
  TwoB{a: U32, b: U32}

law dir_val:
  for d: Dir
  U32

def dir_val(d):
  match d:
    case Nn{}:
      1
    case Ss{}:
      2

law code_val:
  for c: Code
  U32

def code_val(c):
  match c:
    case Cc{v}:
      v

law toss:
  for d: Dir
  for x: U32
  U32

def toss(d, x):
  x

law box_val:
  for b: BoxB
  U32

def box_val(b):
  match b:
    case NilB{}:
      0
    case TwoB{a, b}:
      U32.add(a, b)

law spin:
  for +i  : Nat
  for acc : U32
  U32

def spin(i, acc):
  match i:
    case 0n:
      acc
    case 1n+p:
      +d = {Nn{} : Dir}
      +c = {Cc{U32.add(U32.from_nat(p), 41)} : Code}
      a1 = U32.add(dir_val(d), dir_val(d))
      a2 = U32.add(code_val(c), code_val(c))
      a3 = box_val(TwoB{U32.add(U32.from_nat(p), 1), 3})
      spin(p, toss(Ss{}, U32.mod(U32.add(U32.add(U32.add(acc, a1), a2), a3), 65521)))

law main.out:
  U32

def main.out():
  spin(10n, 0)

law main:
  IO(Unit)

def main():
  IO.print(U32.show(main.out()))

#|1015
