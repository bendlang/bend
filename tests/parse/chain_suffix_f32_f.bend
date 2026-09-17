# ": F32" is the float spelling: the dotted family (+. <. ==.) is
# gone; a comparison chain answers Bool, its suffix names the operand
# type, not the result; float equality is the F32.is_eq call
import Base

def main(a: F32, b: F32, c: F32) -> F32:
  (a + b * c : F32)

def g(a: F32, b: F32) -> Bool:
  (a < b : F32)

def h(a: F32, b: F32) -> Bool:
  F32.is_eq(a, b)

#|a => b => c => F32.add(a, F32.mul(b, c))
