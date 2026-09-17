# Witness for the sharable spare that may hand back 0.
#
# go keeps p, so Duo enters the keeps set and becomes sharable: its
# matches destructure through ctr_take, which parks a spare that is 0
# when the node was shared rather than owned. swap then rebuilds a Duo
# of the same size in that same branch, so ctr_pack reuses that spare
# and must emit the guarded form, nd = sp ? sp : heap_alloc(..). It
# also drives rfc_seal on the rebuilt fields.
#
# bench/matmul parks 18 such spares and reuses none, so the guarded
# form is otherwise never emitted. go answers sum(swap(p)) + sum(p) =
# (3+2) + (2+3), so expect 10n.

import Base

type Duo is Data:
  Dd{a: Nat, b: Nat}

law swap:
  for p: Duo
  Duo

def swap(p):
  match p:
    case Dd{a, b}:
      Dd{b, a}

law sum:
  for p: Duo
  Nat

def sum(p):
  match p:
    case Dd{a, b}:
      Nat.add(a, b)

law go:
  for +p: Duo
  Nat

def go(p):
  Nat.add(sum(swap(p)), sum(p))

law main.out:
  Nat

def main.out():
  go(Dd{2n, 3n})

law main:
  IO(Unit)

def main():
  IO.print(String.append(Nat.show(main.out()), "n"))

#|10n
