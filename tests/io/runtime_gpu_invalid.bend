# A long malformed GPU size must be rejected without quadratic backtracking.
# JS-only: launches a freshly emitted program through its runtime CLI.
import Base

def Host.runtime_gpu_invalid() -> IO(U32):
  import "./runtime_gpu_invalid.js"

def main() -> IO(Unit):
  do IO<Unit>:
    code : U32 <- Host.runtime_gpu_invalid()
    IO.print(U32.show(code))

#|0
