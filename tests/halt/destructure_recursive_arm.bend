# regression pin carried from bend3 (09b3921): a ctor destructure of a
# recursive call -- the scrutinee snf must keep the compact call
# spine, never re-expand arms per layer. The zero-test decision rides
# a worker def over the recursive result (a computed match is a
# banned form), a Nat fuel rides ahead of the self-call (the queens
# shape); the doubled word wears +U32, a Cop.
# ported from bend3: (n == 0) becomes U32.is_zero's Bool; the
# let-bound w folds into the destructure (equivalent, and one
# statement shorter -- reg_body_local_match pins the unfolded
# spelling)
import Base

type P is Data:
  Pr{a: U32, b: U32}

law f:
  for  k: Nat
  for +n: U32
  P

law f.dec:
  for z: Bool
  for r: P
  P

def f.dec(z, r):
  match z:
    case False{}:
      Pr{a, b} = r
      Pr{a, U32.add(b, 1)}
    case True{}:
      Pr{0, 0}

def f(k, n):
  match k:
    case 0n:
      Pr{0, 0}
    case 1n+j:
      f.dec(U32.is_zero(n), f(j, U32.sub(n, 1)))

law main.out:
  Nat

law main.rd:
  for r: P
  Nat

def main.rd(r):
  Pr{a, b} = r
  U32.to_nat(b)

def main.out():
  main.rd(f(16n, 10))

law main:
  IO(Unit)

def main():
  IO.print(String.append(Nat.show(main.out()), "n"))

#|10n
