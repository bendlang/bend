# Interrupted writes must resume at the first byte not yet written.
import Base
import ./file_binary.bend as T

def tmp(salt: U32) -> String:
  "/tmp/bend_t_io_write_interrupted_" ++ U32.show(salt)

def Interrupted.arm(file: File) -> IO(File):
  import "./file_write_interrupted.c"
  import "./file_write_interrupted.js"

def Interrupted.check(file: File) -> IO(File):
  import "./file_write_interrupted.c"
  import "./file_write_interrupted.js"

def main() -> IO(Unit):
  do IO<Unit>:
    +salt : U32 <- IO.try(U32, IO.random_u32())
    f : File <- IO.try(File, File.open(tmp(salt), "w"))
    f : File <- Interrupted.arm(f)
    p : File & Result<&1, &1, U32 & String, Unit> <- File.write(f, "aéλz")
    f : File <- T.wrote(p)
    f : File <- Interrupted.check(f)
    File.close(f)
    f : File <- IO.try(File, File.open(tmp(salt), "r"))
    p : File & Result<&1, &1, U32 & String, List<&2, U32>> <- File.read_bytes(f, 32)
    f : File <- T.read(p, [97, 195, 169, 206, 187, 122], "text written once")
    File.close(f)
    f : File <- IO.try(File, File.open(tmp(salt), "w"))
    f : File <- Interrupted.arm(f)
    p : File & Result<&1, &1, U32 & String, Unit> <-
      File.write_bytes(f, [0, 255, 13, 10, 65, 0, 255])
    f : File <- T.wrote(p)
    f : File <- Interrupted.check(f)
    File.close(f)
    f : File <- IO.try(File, File.open(tmp(salt), "r"))
    p : File & Result<&1, &1, U32 & String, List<&2, U32>> <- File.read_bytes(f, 32)
    f : File <- T.read(p, [0, 255, 13, 10, 65, 0, 255], "bytes written once")
    done : Unit <- File.close(f)
    gone : Result<&1, &1, U32 & String, U32 & (String & String)> <-
      Process.run("rm", ["-f", tmp(salt)], "", 128, 1000)
    return done

#|text written once
#|bytes written once
