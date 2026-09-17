# the stuck family's closed twin (HVM4 red_prd): the predecessor twice
# over 4n (HVM4 dup'd the ref; a ref is shared here as written).
import Base

law prd:
  for a: Nat
  Nat

def prd(a):
  match a:
    case 0n:
      0n
    case 1n+p:
      p

law main:
  Nat

def main():
  prd(prd(4n))

#|2n
