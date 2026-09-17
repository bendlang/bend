# fuel-bounded loops (the GUIDE's fuel idiom): Euclid's gcd and a Collatz
# step count, both driven by a decreasing first column
# ported from bend3: fuel becomes Nat, U32 sub-matches become nested Bool
# matches, shared words +U32 binders
import Base

law gcd.step:
  for  a: U32
  for +b: U32
  for  z: Bool
  U32 & U32

def gcd.step(a, b, z):
  match z:
    case True{}:
      (a, 0)
    case False{}:
      (b, U32.mod(a, b))

law gcd.go:
  for st: U32 & U32
  U32 & U32

def gcd.go(st):
  (a, b0) = st
  +b = {b0 : U32}
  gcd.step(a, b, U32.is_zero(b))

law gcd:
  for fuel : Nat
  for st   : U32 & U32
  U32 & U32

def gcd(fuel, st):
  match fuel:
    case 0n:
      st
    case 1n+f:
      gcd(f, gcd.go(st))

law gcd.pick:
  for a: U32
  for z: Bool
  U32

def gcd.pick(a, z):
  match z:
    case True{}:
      a
    case False{}:
      0

law gcd.fin:
  for w: U32 & U32
  U32

def gcd.fin(w):
  (a, b0) = w
  +b = {b0 : U32}
  gcd.pick(a, U32.is_zero(b))

law collatz.odd:
  for +n    : U32
  for steps : U32
  for z     : Bool
  U32 & U32

def collatz.odd(n, steps, z):
  match z:
    case True{}:
      (U32.div(n, 2), U32.add(steps, 1))
    case False{}:
      (U32.add(U32.mul(3, n), 1), U32.add(steps, 1))

law collatz.step:
  for +n    : U32
  for steps : U32
  for e     : Bool
  U32 & U32

def collatz.step(n, steps, e):
  match e:
    case True{}:
      (n, steps)
    case False{}:
      collatz.odd(n, steps, U32.is_zero(U32.mod(n, 2)))

law collatz.go:
  for st: U32 & U32
  U32 & U32

def collatz.go(st):
  (n0, steps) = st
  +cn = {n0 : U32}
  collatz.step(cn, steps, U32.is_eq(cn, 1))

law collatz:
  for fuel : Nat
  for st   : U32 & U32
  U32 & U32

def collatz(fuel, st):
  match fuel:
    case 0n:
      st
    case 1n+f:
      collatz(f, collatz.go(st))

law collatz.pick:
  for steps : U32
  for z     : Bool
  U32

def collatz.pick(steps, z):
  match z:
    case True{}:
      steps
    case False{}:
      9999

law collatz.fin:
  for w: U32 & U32
  U32

def collatz.fin(w):
  (n0, steps) = w
  +cn = {n0 : U32}
  collatz.pick(steps, U32.is_eq(cn, 1))

law main.out:
  U32

def main.out():
  U32.add(U32.mul(gcd.fin(gcd(10n, (1071, 462))), 1000), collatz.fin(collatz(120n, (27, 0))))

law main:
  IO(Unit)

def main():
  IO.print(U32.show(main.out()))

#|21111
