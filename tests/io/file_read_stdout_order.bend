# io (file_read_stdout_order): IO.print holds stdout off a terminal, and
# a File read may block on a peer that waits for it, so the held text
# goes out before the read. raw_two writes to fd 1 past the runtime, so a
# line still held at the read comes out after it.
import Base

def tmp(salt: U32) -> String:
  "/tmp/bend_t_io_file_read_stdout_order_" ++ U32.show(salt)

def raw_two() -> IO(Unit):
  import "./file_read_stdout_order.c"
  import "./file_read_stdout_order.js"

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
    IO.print("one")
    g : File <- IO.try(File, File.open(tmp(salt), "r"))
    r : File & Result<&1, &1, U32 & String, String> <- File.read_line(g, 64)
    Unit <- read(r)
    Unit <- raw_two()
    done : Unit <- IO.print("three")
    gone : Result<&1, &1, U32 & String, U32 & (String & String)> <-
      Process.run("/bin/rm", ["-f", tmp(salt)], "", 128, 1000)
    return done

#|one
#|two
#|three
