# io (io_hello_print): main : IO(U32) runs through the interpreter's
# event loop: IO.print is a FOREIGN def (a fill of import lines; the
# loop runs base's ./effs/print.js), the do block binds through
# IO.bind, and the terminal Emit's word is discarded (exit 0) -- a
# program prints only what it prints through IO. The --js lane is the
# same program compiled: the emitted event loop trampolines each
# effect request through the same spliced ./effs/print.js.
import Base

law main:
  IO(U32)

def main():
  do IO<U32>:
    x : Unit <- IO.print("hello")
    return 0

#|hello
