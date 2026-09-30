# a meet in live code goes to --verdict as a match on its left side, which
# the kernel's live check reads (it reads no meet): m is a meet of two
# run-time quantities, and main's closed meet folds to &1. The laws check
# every row of m's table in the emitted book
import Base

def keep(q: Quant, -A: Kind(q), x: A) -> A:
  x

def m(a: Quant, b: Quant) -> Quant:
  a <&> b

law table:
  {m(&0, &0) == &0 : Quant} & {m(&0, &1) == &0 : Quant} & {m(&0, &2) == &0 : Quant}
  & {m(&1, &0) == &0 : Quant} & {m(&1, &1) == &1 : Quant} & {m(&1, &2) == &1 : Quant}
  & {m(&2, &0) == &0 : Quant} & {m(&2, &1) == &1 : Quant} & {m(&2, &2) == &2 : Quant}

def table():
  ({==}, {==}, {==}, {==}, {==}, {==}, {==}, {==}, {==})

def main() -> Nat:
  keep(m(&1, &2), Nat, keep(&2 <&> &1, Nat, 3n))

#|3n
