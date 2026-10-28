# File opens must retry EINTR and preserve other errors.
import Base
import ./file_binary.bend as T

def Interrupted.arm() -> IO(Unit):
  import "./file_open_interrupted.c"
  import "./file_open_interrupted.js"

def Interrupted.check() -> IO(Unit):
  import "./file_open_interrupted.c"
  import "./file_open_interrupted.js"

def main() -> IO(Unit):
  do IO<Unit>:
    Interrupted.arm()
    f : File <- IO.try(File, File.open("/dev/null", "r"))
    Interrupted.check()
    File.close(f)
    IO.print("text path opens after interruptions")
    Interrupted.arm()
    f : File <- IO.try(File,
      File.open_bytes([47, 100, 101, 118, 47, 110, 117, 108, 108], "r"))
    Interrupted.check()
    File.close(f)
    IO.print("byte path opens after interruptions")
    Interrupted.arm()
    r : Result<&1, &1, U32 & String, File> <- File.open("/dev/null", "x")
    Interrupted.check()
    T.failed(File, r, 17, "text path preserves EEXIST")
    Interrupted.arm()
    r : Result<&1, &1, U32 & String, File> <-
      File.open_bytes([47, 100, 101, 118, 47, 110, 117, 108, 108], "x")
    Interrupted.check()
    T.failed(File, r, 17, "byte path preserves EEXIST")

#|text path opens after interruptions
#|byte path opens after interruptions
#|text path preserves EEXIST
#|byte path preserves EEXIST
