# the refusal half of the + binder law: a Many (+) binder whose type's
# kind does not reduce to Data is a formation error -- an opaque
# -T: Type binds Kind(&1), never Data
import Base

law twice:
  for -T: Type
  for +x: T
  T & T

def twice(T, x):
  (x, x)

law main:
  Nat

def main():
  0n

#|Error:
#|- expected : Data
#|- observed : Type
#|Context:
#|- T : Type
#|Location: twice
#|7 |   for -T: Type
#|8>|   for +x: T
#|  |           ^
#|9 |   T & T
#|exit 1
