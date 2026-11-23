# io (file_read_line_stdout_order): a File.read_line that reads its fd
# flushes the stdout IO.print holds first, on a handle opened before the
# print, even while another fiber keeps the loop from its poller. On the
# C lane the armed read fails the program if stdout was not flushed.
import Base

def tmp(salt: U32) -> String:
  "/tmp/bend_t_io_file_read_line_stdout_order_" ++ U32.show(salt)

def read_arm(file: File) -> IO(File):
  import "./file_read_line_stdout_order.c"
  import "./file_read_line_stdout_order.js"

def wait_for_read() -> IO(Unit):
  import "./file_read_line_stdout_order.c"
  import "./file_read_line_stdout_order.js"

def closed(pair: File & Result<&1, &1, U32 & String, Unit>) -> IO(Unit):
  (file, result) = pair
  File.close(file)

def read(pair: File & Result<&1, &1, U32 & String, String>) -> IO(Unit):
  (file, result) = pair
  File.close(file)

def main() -> IO(Unit):
  do IO<Unit>:
    +salt : U32 <- IO.try(U32, IO.random_u32())
    f : File <- IO.try(File, File.open(tmp(salt), "w"))
    w : File & Result<&1, &1, U32 & String, Unit> <- File.write(f, "x\n")
    Unit <- closed(w)
    g : File <- IO.try(File, File.open(tmp(salt), "r"))
    g : File <- read_arm(g)
    IO.spawn(Unit, wait_for_read())
    IO.print("one")
    r : File & Result<&1, &1, U32 & String, String> <- File.read_line(g, 64)
    Unit <- read(r)
    done : Unit <- IO.print("two")
    gone : Result<&1, &1, U32 & String, U32 & (String & String)> <-
      Process.run("rm", ["-f", tmp(salt)], "", 128, 1000)
    return done

#|one
#|two
