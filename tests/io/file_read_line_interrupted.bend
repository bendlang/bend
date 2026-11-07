# An interrupted first read of File.read_line must retry and answer the
# line, without looking at a byte before the buffer.
import Base
import ./file_binary.bend as T

def Interrupted.arm(file: File) -> IO(File):
  import "./file_read_line_interrupted.c"
  import "./file_read_line_interrupted.js"

def Interrupted.check(file: File) -> IO(File):
  import "./file_read_line_interrupted.c"
  import "./file_read_line_interrupted.js"

def line(m: File & Result<&1, &1, U32 & String, String>) -> IO(File):
  (f, r) = m
  do IO<File>:
    s : String <- IO.pass(String, r)
    u : Unit <- IO.print("[" ++ s ++ "]")
    return f

def main() -> IO(Unit):
  do IO<Unit>:
    salt : U32 <- IO.try(U32, IO.random_u32())
    +path : String = "/tmp/bend_io_read_line_interrupted_" ++ U32.show(salt)
    f : File <- IO.try(File, File.open(path, "w"))
    w : File & Result<&1, &1, U32 & String, Unit> <- File.write(f, "ab\ncd")
    f : File <- T.wrote(w)
    File.close(f)
    g : File <- IO.try(File, File.open(path, "r"))
    g : File <- Interrupted.arm(g)
    m : File & Result<&1, &1, U32 & String, String> <- File.read_line(g, 64)
    g : File <- line(m)
    g : File <- Interrupted.check(g)
    done : Unit <- File.close(g)
    gone : Result<&1, &1, U32 & String, U32 & (String & String)> <-
      Process.run("/bin/rm", ["-f", path], "", 128, 1000)
    return done

#|[ab
#|]
