# bend3's harness-cache adversary, purity side: interleaved --eval
# blocks of DIFFERENT defs repeated byte-identically off one cached
# book. bend's runner caches the checked book per file; interleaved
# --show pages of two defs and the value block must repeat unchanged
import Base

law grow:
  for n: Nat
  Nat

def grow(n):
  match n:
    case Zero{}:
      1n
    case Succ{k}:
      Succ{Succ{grow(k)}}

law main:
  for n: Nat
  Nat

def main(n):
  match n:
    case Zero{}:
      0n
    case Succ{k}:
      k

#|\{Zero: 0n; Succ: (k => k)}
