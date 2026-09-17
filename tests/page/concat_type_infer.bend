# ++ never infers an element: it is String.append, so a list operand
# is refused against String -- lists concat as LL.append(A, ..)
# (bend3's page inferred the Cat element from the goal)
import Base

law LL.append:
  for -A: Type
  for xs: List<&1, A>
  for ys: List<&1, A>
  List<&1, A>

def LL.append(A, xs, ys):
  match xs:
    case Nil{}:
      ys
    case h <> t:
      h <> LL.append(A, t, ys)

law main:
  List<&1, U32>

def main():
  [1] ++ [2]

#|Error:
#|- expected : String
#|- observed : List
#|Location: main
#|22 | def main():
#|23>|   [1] ++ [2]
#|24 |
#|exit 1
