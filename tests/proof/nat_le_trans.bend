# Base Nat ordering as a type FAMILY: LE computes to Unit on concrete
# pairs, le_trans chains them, and the family (refl/zero/succ/antisym)
# instantiates
# ported from bend3: evidence params are trailing (a, b, c, ab, bc), not
# interleaved; Unit's value is Unit{}; the checker-silent bend3 golden
# becomes the interp lane printing main's Unit witness
import Base

law Nat.LE:
  for a: Nat
  for b: Nat
  Type

def Nat.LE(a, b):
  match a b:
    case 0n y:
      Unit
    case 1n+x 0n:
      Empty
    case 1n+x 1n+y:
      Nat.LE(x, y)

law Nat.le_refl:
  for a: Nat
  Nat.LE(a, a)

def Nat.le_refl(a):
  match a:
    case 0n:
      Unit{}
    case 1n+x:
      Nat.le_refl(x)

law Nat.le_zero:
  for -b: Nat
  Nat.LE(0n, b)

def Nat.le_zero(b):
  Unit{}

law Nat.le_succ:
  for a: Nat
  for b: Nat
  for e: Nat.LE(a, b)
  Nat.LE(a, 1n+b)

def Nat.le_succ(a, b, e):
  match a:
    case 0n:
      Unit{}
    case 1n+x:
      match b:
        case 0n:
          Empty.absurd(Nat.LE(x, 0n), e)
        case 1n+y:
          Nat.le_succ(x, y, e)

law Nat.le_trans:
  for a  : Nat
  for b  : Nat
  for c  : Nat
  for ab : Nat.LE(a, b)
  for bc : Nat.LE(b, c)
  Nat.LE(a, c)

def Nat.le_trans(a, b, c, ab, bc):
  match a:
    case 0n:
      Unit{}
    case 1n+x:
      match b:
        case 0n:
          Empty.absurd(Nat.LE(1n+x, c), ab)
        case 1n+y:
          match c:
            case 0n:
              Empty.absurd(Nat.LE(1n+x, 0n), bc)
            case 1n+z:
              Nat.le_trans(x, y, z, ab, bc)

law Nat.le_antisym:
  for a  : Nat
  for b  : Nat
  for ab : Nat.LE(a, b)
  for ba : Nat.LE(b, a)
  {a == b : Nat}

def Nat.le_antisym(a, b, ab, ba):
  match a b:
    case 0n 0n:
      {==}
    case 0n 1n+y:
      Empty.absurd({0n == 1n+y : Nat}, ba)
    case 1n+x 0n:
      Empty.absurd({1n+x == 0n : Nat}, ab)
    case 1n+x 1n+y:
      Equal.cong(Nat, Nat, k => 1n+k, x, y, Nat.le_antisym(x, y, ab, ba))

law e13:
  Nat.LE(1n, 3n)

def e13():
  Nat.le_trans(1n, 2n, 3n, Unit{}, Unit{})

law refl9:
  Nat.LE(9n, 9n)

def refl9():
  Nat.le_refl(9n)

law zero7:
  Nat.LE(0n, 7n)

def zero7():
  Nat.le_zero(7n)

law succ25:
  Nat.LE(2n, 5n)

def succ25():
  Nat.le_succ(2n, 4n, Nat.le_succ(2n, 3n, Nat.le_succ(2n, 2n, Nat.le_refl(2n))))

law anti4:
  {4n == 4n : Nat}

def anti4():
  Nat.le_antisym(4n, 4n, Nat.le_refl(4n), Nat.le_refl(4n))

law main:
  Nat.LE(1n, 3n)

def main():
  e13()

#|Unit{}
