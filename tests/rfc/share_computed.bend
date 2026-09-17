# rfc (rfc_share_computed): a shared binder whose type is computed,
# pick(b), a match on a value. The sharing analysis names a plain type
# parameter with a probe; a Mat is no name, so the analysis must fall
# back to heating every site type (cb.wild), or Duo stays cold, its
# node opens raw behind the count-2 cell the keep put in front of it,
# and the C lanes died "bend: error 7" on the garbage Nat. Expect 6n
# on every lane.
import Base

type Duo is Data:
  Dd{a: Nat, b: Nat}

law pick:
  for b: Bool
  Data

def pick(b):
  match b:
    case True{}:
      Duo
    case False{}:
      Nat

law opn:
  for m: Duo
  Nat

def opn(m):
  match m:
    case Dd{a, b}:
      Nat.add(a, b)

law twice:
  for b: Bool
  for +x: pick(b)
  for f: pick(b) -> Nat
  for g: pick(b) -> Nat
  Nat

def twice(b, x, f, g):
  Nat.add(f(x), g(x))

law main.out:
  Nat

def main.out():
  twice(True{}, Dd{1n, 2n}, opn, opn)

law main:
  IO(Unit)

def main():
  IO.print(String.append(Nat.show(main.out()), "n"))

#|6n
