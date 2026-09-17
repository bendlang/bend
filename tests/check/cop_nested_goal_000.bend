# the + license reads the binder type's KIND, which whnfs through
# nested alias applications and terminates -- a Data-declared alias of
# a Data-declared alias of Nat licenses +x, and the check completes
import Base

law N1:
  Data

def N1(): Nat

law N2:
  for -T: Data
  Data

def N2(T): N1

law twice:
  for +x: N2(N2(Nat))
  Nat

def twice(x):
  Nat.add(x, x)

law main:
  Nat

def main():
  twice(3n)

#|6n
