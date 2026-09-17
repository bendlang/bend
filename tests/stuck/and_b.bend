# the stuck family (HVM4 red_and_stuck_b): a closed first argument
# picks the arm, and the open second argument is the answer.
import Base

law and:
  for a: Bool
  for b: Bool
  Bool

def and(a, b):
  match a:
    case False{}:
      False{}
    case True{}:
      b

law main:
  @x:Bool -> Bool

def main():
  x => and(True{}, x)

#|x => x
