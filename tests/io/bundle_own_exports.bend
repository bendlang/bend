# A page that uses one def of a module ships only what that def reaches: the
# module exports its own defs, and an imported file's defs stay internal.
import Base

def Bundle.own_exports() -> IO(U32):
  import "./bundle_own_exports.js"

def main() -> IO(Unit):
  do IO<Unit>:
    value : U32 <- Bundle.own_exports()
    IO.print(U32.show(value))

#|0
