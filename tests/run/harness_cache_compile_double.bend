# bend3's harness-cache adversary, compile side: compile and eval
# blocks shared one cached checked book and stayed pure. bend's
# runner shares one in-process book across a file's blocks the same
# way (no --compile flag; --show is the compile-side page): the value
# and the rendered page must repeat byte-identically
import Base

law main:
  for n: Nat
  Nat

def main(n):
  match n:
    case Zero{}:
      0n
    case Succ{k}:
      Succ{Succ{main(k)}}

#|\{Zero: 0n; Succ: (k => 2n+main(k))}
