# Waiting is defined for one positive process ID, never a process group.
import Base
import ./file_binary.bend as T

def main() -> IO(Unit):
  do IO<Unit>:
    zero : Result<&1, &1, U32 & String, U32> <- Process.wait(0)
    T.failed(U32, zero, 22, "wait rejects process group zero")
    high : Result<&1, &1, U32 & String, U32> <- Process.wait(4294967295)
    T.failed(U32, high, 22, "wait rejects a signed-negative pid")
    absent : Result<&1, &1, U32 & String, U32> <- Process.wait(1)
    T.failed(U32, absent, 10, "wait rejects a non-child")

#|wait rejects process group zero
#|wait rejects a signed-negative pid
#|wait rejects a non-child
