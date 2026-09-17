# the stuck family's closed twin (HVM4 red_and_tf): and(True{}, False{}).
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
  Bool

def main():
  and(True{}, False{})

#|False{}
