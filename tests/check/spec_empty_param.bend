# v is specialized, and Void has no constructors: safe.ts went out once
# per constructor, so skip went out zero times, and --verdict passed a def
# the kernel never checked. An empty type's parameter now goes out at an
# opaque constant, as any other type's does, so the kernel checks skip's
# body; a body that names v would be out of scope, for want of a model
# (#1186)
import Base

type Void is Data:

law skip:
  for ~v: Void
  for n: Nat
  Nat

def skip(v, n):
  n

def main() -> Nat:
  3n

#|3n
