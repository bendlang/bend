# a module may not declare a name Base declares: shadow_lib's Nat.add is
# refused as it is in the root namespace (it once reached its importer as
# L.Nat.add, beside Base's)
import Base
import ./shadow_lib.bend as L

def main() -> IO(Unit):
  IO.print(Bool.show(L.Nat.add(1n, 2n)))

#|Error:
#|- expected : a fresh name (duplicate declaration: Nat.add)
#|- observed : 'Nat.add'
#|Location:
#|5 |
#|6>| def Nat.add(a: Nat, b: Nat) -> Bool:
#|  |     ^^^^^^^
#|7 |   True{}
#|exit 1
