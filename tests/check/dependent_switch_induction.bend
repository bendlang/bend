# bend3's U32 induction: a switch against a dependent goal specialized
# per arm, `1+p` binding the successor witness and the recursive call
# the induction hypothesis. bend ruled the surface out -- U32 is a
# wrapper datatype with no 1+ pattern (numeric induction rides Nat,
# pinned by the nat_proofs ports); the spelling dies at the pattern
import Base

law down:
  for n: U32
  U32

def down(n):
  match n:
    case 0:
      0
    case 1+p:
      down(p)

law down_zero:
  for n: U32
  {down(n) == 0 : U32}

def down_zero(n):
  match n:
    case 0:
      {==}
    case 1+p:
      down_zero(p)

law main:
  U32

def main():
  0

#|Error:
#|- expected : 1 patterns (one per scrutinee)
#|- observed : '
#|'
#|Location:
#|15 |       0
#|16>|     case 1+p:
#|17 |       down(p)
#|exit 1
