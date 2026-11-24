# An exported def takes a U32 masked to 32 bits, in one call or curried:
# 2^32 is 0 and -1 is 2^32-1 to every U32 operation alike, so show,
# is_zero and add agree on one argument.
import Base

def U32.host_export() -> IO(U32):
  import "./u32_host_export.js"

def main() -> IO(Unit):
  do IO<Unit>:
    value : U32 <- U32.host_export()
    IO.print(U32.show(value))

#|0
