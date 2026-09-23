# a float literal prints back as its number, and a term built on float
# literals prints as it was written
import Base

def wide(a: F32) -> F32:
  F32.add(3.14159, a)

def main(a: F32, b: F32) -> F32:
  F32.add(wide(a), F32.add(1.5e3, b))

#|a => b => F32.add(F32.add(3.14159, a), F32.add(1500.0, b))
