# rfc (rfc_share_kind): a shared binder whose type is a type function
# applied, F(A), with F and A the def's own erased parameters. The
# sharing analysis names a plain type parameter with a probe and heats
# what the callers pass for it; F(A) is a stuck application, no name to
# carry, so the analysis must fall back to heating every site type
# (cb.wild), or the Maybe<Duo> the caller passes stays cold, its node
# opens raw behind the count-2 cell the keep put in front of it, and
# the sum came out 128 (a garbage Nat) instead of 6. Expect 6n on
# every lane.
import Base

type Duo is Data:
  Dd{a: Nat, b: Nat}

law opn:
  for m: Maybe<&2, Duo>
  Nat

def opn(m):
  match m:
    case Some{Dd{a, b}}:
      Nat.add(a, b)
    case None{}:
      0n

law twice:
  for -F: Data -> Data
  for -A: Data
  for +x: F(A)
  for f: F(A) -> Nat
  for g: F(A) -> Nat
  Nat

def twice(F, A, x, f, g):
  Nat.add(f(x), g(x))

law main.out:
  Nat

def main.out():
  twice(A => Maybe<&2, A>, Duo, Some{Dd{1n, 2n}}, opn, opn)

law main:
  IO(Unit)

def main():
  IO.print(String.append(Nat.show(main.out()), "n"))

#|6n
