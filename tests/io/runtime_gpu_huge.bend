# A GPU size past 2^64 bytes is rejected before it becomes a byte count,
# on both runtimes: the C runtime once cast it to u64 out of range (UB,
# saturating to 16 EiB on arm64) and ran on it.
# JS-only: builds a freshly emitted program and launches it through its
# runtime CLI, as C and as JS.
import Base

def Host.runtime_gpu_huge() -> IO(U32):
  import "./runtime_gpu_huge.js"

def main() -> IO(Unit):
  do IO<Unit>:
    code : U32 <- Host.runtime_gpu_huge()
    IO.print(U32.show(code))

#|0
