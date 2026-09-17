# nat_table coverage, GOAL 1.4: a closed Nat match of three-plus
# constant word arms is the general embedded-data idiom (a month
# table), not a raytrace privilege -- it must compile to one deduped
# CONSTV table with a clamped TAB_AT lookup whose last entry is the
# Succ default. year() walks the table with a dynamic index and its
# call sits past the inliner's fold horizon, so the match survives
# to runtime instead of constant-folding away.
import Base

law days:
  for m: Nat
  U32

def days(m):
  match m:
    case 0n: 31
    case 1n: 28
    case 2n: 31
    case 3n: 30
    case 4n: 31
    case 5n: 30
    case 6n: 31
    case 7n: 31
    case 8n: 30
    case 9n: 31
    case 10n: 30
    case 11n+k: 31

law year:
  for +m: Nat
  U32

def year(m):
  match m:
    case 0n:
      0
    case 1n+p:
      U32.add(days(p), year(p))

law main:
  IO(Unit)

def main():
  IO.print(U32.show(year(100n)))

#|3093
