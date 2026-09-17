# bend3 pinned that minted binders print as valid source names; bend's
# flattener mints them at nested patterns and the --show lane renders
# them (_6 here), a name the parser takes back
import Base

law main:
  for n: Nat
  Nat

def main(n):
  match n:
    case Succ{Succ{x}}:
      2n
    case n:
      0n

#|\{Succ: \{Succ: (x => 2n); (_4 => 0n)}; (n => 0n)}
