# stuck float builtins print as their spelling under the open binders
# (F32 ops are base asserts: machine ops never reduce on open words;
# base-native asserts are live-usable strict). the reused y splits
# into two binders, since a lambda binder is never Many
import Base

law main:
  @y:F32 -> @z:F32 -> F32

def main():
  y => z => F32.add(F32.sqrt(y), z)

#|y => z => F32.add(F32.sqrt(y), z)
