# check_chained_switch_conflation_000's sound ACCEPT twin rode the
# Inc/ADD bridge under a nested 1+q arm. bend has neither Inc nor a
# 1+ pattern, so the accepting chain has no spelling either: the same
# parse wall as its rejecting twin, on the reconstruction's own arm
import Base

law reb2:
  for m: U32
  U32

def reb2(m):
  match m:
    case 0:
      0
    case 1:
      1
    case 2+q:
      (2 + q : U32)

law main:
  U32

def main():
  0

#|Error:
#|- expected : 1 patterns (one per scrutinee)
#|- observed : '2+q'
#|Location:
#|16 |       1
#|17>|     case 2+q:
#|   |          ^^^
#|18 |       (2 + q : U32)
#|exit 1
