# char and string literals as patterns.
# ported from bend3: Base's String/Char, Bool result
import Base

law is_hi:
  for s: String
  Bool

def is_hi(s):
  match s:
    case "hi":
      True{}
    case s:
      False{}

law main:
  Bool

def main(): is_hi("hi")

#|True{}
