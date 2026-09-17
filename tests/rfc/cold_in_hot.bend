# rfc (rfc_cold_in_hot): a cold record inside a hot constructor. keep shares a
# List<U32>, so Con is hot: every Con build seals its head and every Con match
# takes its fields through ctr_take. pairs builds a List<Duo> that nobody
# shares, so Duo alone would stay cold and open raw, yet its node arrives behind
# the count-1 cell the hot Con put in front of it. The site-type fixpoint of
# facts_build heats the type arguments of every instantiation of a hot type
# (Duo, through the List<Duo> binder of total), so Duo opens through ctr_take
# too. With that fixpoint gone (it once went with the closure flag), the raw
# open read the cell as the node and both C lanes died "bend: error 8" on the
# garbage Nat; the hvm5_interp demo's List<Ent> lost @main the same way. Expect
# 12n + 4n on every lane.
import Base

type Duo is Data:
  Dd{a: Nat, b: Nat}

law count:
  for xs: List<&2, U32>
  U32

def count(xs):
  match xs:
    case Nil{}:
      0
    case h <> t:
      U32.add(1, count(t))

law keep:
  for +xs: List<&2, U32>
  U32

def keep(xs):
  U32.add(count(xs), count(xs))

law pairs:
  for n: Nat
  List<&2, Duo>

def pairs(n):
  match n:
    case 0n:
      Nil{}
    case 1n+p:
      Dd{1n, 2n} <> pairs(p)

law total:
  for ds: List<&2, Duo>
  Nat

def total(ds):
  match ds:
    case Nil{}:
      0n
    case Dd{a, b} <> r:
      Nat.add(Nat.add(a, b), total(r))

law main.out:
  Nat

def main.out():
  Nat.add(total(pairs(4n)), U32.to_nat(keep([1, 2])))

law main:
  IO(Unit)

def main():
  IO.print(String.append(Nat.show(main.out()), "n"))

#|16n
