# slab-array pin (check_array_not_data): bend3's array boundary --
# contraction is free on Data and arrays are not Data, so an aliased
# array binder stayed a Usage error. bend has no [:T] array type --
# the [: spelling in f's parameters pins bend's own parse refusal
# (bend is affine at every type; the capture twins pin that wall).
import Base

law f:
  for a: [:U32]
  for b: [:U32]
  U32

def f(a, b):
  x = a@a1[0]
  y = b@b1[0]
  (x + y : U32)

law main:
  U32

def main():
  arr = (![0:5, _:0; 1] : [:U32])
  f(arr, arr)

#|Error:
#|- expected : a term
#|- observed : ':'
#|Location:
#| 8 | law f:
#| 9>|   for a: [:U32]
#|   |           ^
#|10 |   for b: [:U32]
#|exit 1
