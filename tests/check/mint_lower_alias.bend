# bend3's mint-lowering alias witness (a split mint re-basing c^4 over
# c^3); bend mints nothing and stores elaborated bodies once, so the
# colliding-name shape has no machinery to alias: a field binder
# shadowing its own param beside a forall of the same name checks and
# the conversion closes
import Base

law shadow_ok:
  for n: Nat
  for c: Nat
  Nat

def shadow_ok(n, c):
  match n:
    case Zero{}:
      c
    case Succ{c}:
      c

law lem:
  for n: Nat
  @c:Nat -> {shadow_ok(1n+n, c) == n : Nat}

def lem(n):
  c => {==}

law main.out:
  Nat

def main.out():
  0n

law main:
  IO(Unit)

def main():
  IO.print(String.append(Nat.show(main.out()), "n"))

#|0n
