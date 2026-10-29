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
    f : File <- IO.try(File, File.open("/tmp/bend_io_read_line_interrupted", "w"))
    w : File & Result<&1, &1, U32 & String, Unit> <- File.write(f, "ab\ncd")
    f : File <- T.wrote(w)
    File.close(f)
    g : File <- IO.try(File, File.open("/tmp/bend_io_read_line_interrupted", "r"))
    g : File <- Interrupted.arm(g)
    m : File & Result<&1, &1, U32 & String, String> <- File.read_line(g, 64)
    g : File <- line(m)
    g : File <- Interrupted.check(g)
    File.close(g)

#|[ab
#|]
