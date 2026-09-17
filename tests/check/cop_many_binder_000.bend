# a Many (+) binder is legal iff its type's kind reduces to Data:
# +x: Nat is licensed (Nat is Data), and a generic def binds its
# license as a Data-kinded type parameter (-T: Data), which Nat fits
import Base

law twice:
  for +x: Nat
  Nat

def twice(x):
  Nat.add(x, x)

law dup:
  for -T: Data
  for +x: T
  T & T

def dup(T, x):
  (x, x)

law unp:
  for p: Nat & Nat
  Nat

def unp(p):
  Tuple{a, b} = p
  Nat.add(a, b)

law main:
  Nat

def main():
  unp(dup(Nat, twice(2n)))

#|8n
