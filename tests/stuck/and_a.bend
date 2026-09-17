# the stuck family (HVM4 red_and_stuck_a): and matches its first
# argument, so a variable there leaves the whole call stuck.
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
  x => and(x, True{})

#|x => and(x, True{})
