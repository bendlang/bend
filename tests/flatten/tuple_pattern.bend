# nested tuple patterns flatten like any ctor pattern: tuples inside
# tuples, mixed with datatype ctors.
# ported from bend3: Base Nat, arithmetic through U32 calls
import Base

law classify:
  for p: (Nat & Nat) & Nat
  U32

def classify(p):
  match p:
    case ((Zero{}, b), Zero{}):
      0
    case ((Zero{}, b), Succ{n}):
      1
    case ((Succ{a}, b), n):
      2

law pack:
  (Nat & Nat) & Nat

def pack():
  ((1n, 0n), 0n)

law main:
  IO(Unit)

def main():
  n = U32.add(U32.mul(classify(pack()), 10), classify(((0n, 0n), 3n)))
  IO.print(U32.show(n))

#|21
