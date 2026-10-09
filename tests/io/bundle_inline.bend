# Inline page modules share their imports and produce repeatable bundles.
# Syntax diagnostics retain the original HTML page's line coordinates.
import Base

def Bundle.inline() -> IO(U32):
  import "./bundle_inline.js"

def main() -> IO(Unit):
  do IO<Unit>:
    value : U32 <- Bundle.inline()
    IO.print(U32.show(value))

#|0
