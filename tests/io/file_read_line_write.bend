# io (io_file_read_line_write): on an "r+" handle, a write after
# File.read_line lands right after the line, not past what was read ahead,
# and File.read, File.read_line and a fresh handle all see the file as
# written.
import Base

def tmp(salt: U32) -> String:
  "/tmp/bend_t_io_read_line_write_" ++ U32.show(salt)

def written(pair: File & Result<&1, &1, U32 & String, Unit>) -> IO(File):
  (file, result) = pair
  do IO<File>:
    IO.pass(Unit, result)
    return file

def read(pair: File & Result<&1, &1, U32 & String, String>) -> IO(File):
  (file, result) = pair
  do IO<File>:
    text : String <- IO.pass(String, result)
    IO.print("[" ++ text ++ "]")
    return file

def main() -> IO(Unit):
  do IO<Unit>:
    +salt : U32 <- IO.try(U32, IO.random_u32())
    f : File <- IO.try(File, File.open(tmp(salt), "w"))
    p : File & Result<&1, &1, U32 & String, Unit> <- File.write(f,
      "one\ntwo\nthree\nfour\n")
    f : File <- written(p)
    File.close(f)
    f : File <- IO.try(File, File.open(tmp(salt), "r+"))
    p : File & Result<&1, &1, U32 & String, String> <- File.read_line(f, 64)
    f : File <- read(p)
    p : File & Result<&1, &1, U32 & String, Unit> <- File.write(f, "TWO")
    f : File <- written(p)
    p : File & Result<&1, &1, U32 & String, String> <- File.read_line(f, 64)
    f : File <- read(p)
    p : File & Result<&1, &1, U32 & String, String> <- File.read_line(f, 2)
    f : File <- read(p)
    p : File & Result<&1, &1, U32 & String, Unit> <- File.write(f, "R")
    f : File <- written(p)
    p : File & Result<&1, &1, U32 & String, String> <- File.read(f, 64)
    f : File <- read(p)
    File.close(f)
    f : File <- IO.try(File, File.open(tmp(salt), "r"))
    p : File & Result<&1, &1, U32 & String, String> <- File.read(f, 64)
    f : File <- read(p)
    done : Unit <- File.close(f)
    gone : Result<&1, &1, U32 & String, U32 & (String & String)> <-
      Process.run("rm", ["-f", tmp(salt)], "", 128, 1000)
    return done

#|[one
#|]
#|[
#|]
#|[th]
#|[ee
#|four
#|]
#|[one
#|TWO
#|thRee
#|four
#|]
