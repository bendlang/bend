# the stuck family's closed twin (HVM4 red_and_ff): and(False{}, False{}).
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
  and(False{}, False{})

#|False{}
