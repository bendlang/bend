# Loading Base must not change the imported file's declarations or literals.
import Base
import ./shadow_lib.bend as L

def main() -> L.Nat:
  L.Nat.add(L.one(), L.Zero{})

#|shadow_lib.Succ{shadow_lib.Zero{}}
