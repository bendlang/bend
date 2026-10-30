# Interrupted writes must resume at the first byte not yet written.
import Base
import ./file_binary.bend as T

def Interrupted.arm(file: File) -> IO(File):
  import "./file_write_interrupted.c"
  import "./file_write_interrupted.js"

def Interrupted.check(file: File) -> IO(File):
  import "./file_write_interrupted.c"
  import "./file_write_interrupted.js"

def main() -> IO(Unit):
  do IO<Unit>:
    f : File <- IO.try(File, File.open("/tmp/bend_io_write_interrupted", "w"))
    f : File <- Interrupted.arm(f)
    p : File & Result<&1, &1, U32 & String, Unit> <- File.write(f, "aéλz")
    f : File <- T.wrote(p)
    f : File <- Interrupted.check(f)
    File.close(f)
    f : File <- IO.try(File, File.open("/tmp/bend_io_write_interrupted", "r"))
    p : File & Result<&1, &1, U32 & String, List<&2, U32>> <- File.read_bytes(f, 32)
    f : File <- T.read(p, [97, 195, 169, 206, 187, 122], "text written once")
    File.close(f)
    f : File <- IO.try(File, File.open("/tmp/bend_io_write_interrupted", "w"))
    f : File <- Interrupted.arm(f)
    p : File & Result<&1, &1, U32 & String, Unit> <-
      File.write_bytes(f, [0, 255, 13, 10, 65, 0, 255])
    f : File <- T.wrote(p)
    f : File <- Interrupted.check(f)
    File.close(f)
    f : File <- IO.try(File, File.open("/tmp/bend_io_write_interrupted", "r"))
    p : File & Result<&1, &1, U32 & String, List<&2, U32>> <- File.read_bytes(f, 32)
    f : File <- T.read(p, [0, 255, 13, 10, 65, 0, 255], "bytes written once")
    File.close(f)

#|text written once
#|bytes written once
