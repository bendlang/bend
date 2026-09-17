# the plain ternary select coverage, GOAL 1.4: a two-arm Bool match
# whose arms are allocation-free words (pick's own parameters) emits
# as a plain if/else over word locals; the C compiler if-converts it
# to one select. adiff evaluates both subtractions and selects the
# non-wrapping one and answers 198 either way.
import Base

law b2u:
  for b: Bool
  U32

def b2u(b):
  match b:
    case False{}: 0
    case True{}: 1

law pick.go:
  for x: U32
  for y: U32
  for z: Bool
  U32

def pick.go(x, y, z):
  match z:
    case True{}:
      x
    case False{}:
      y

law pick:
  for t: U32
  for x: U32
  for y: U32
  U32

def pick(t, x, y):
  pick.go(x, y, U32.is_zero(t))

law adiff:
  for +a: U32
  for +b: U32
  U32

def adiff(a, b):
  pick(b2u(U32.is_lt(a, b)), U32.sub(a, b), U32.sub(b, a))

law wob:
  for +i: Nat
  U32

def wob(i):
  match i:
    case 0n:
      0
    case 1n+p:
      a = U32.mod(U32.from_nat(p), 13)
      b = U32.mod(U32.from_nat(p), 7)
      U32.add(adiff(a, b), wob(p))

law main:
  IO(Unit)

def main():
  IO.print(U32.show(wob(50n)))

#|198
