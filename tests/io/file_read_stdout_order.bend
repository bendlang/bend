# io (file_read_stdout_order): IO.print holds stdout off a terminal, and
# a File read may block on a peer that waits for it, so the held text
# goes out before the read. raw_two writes to fd 1 past the runtime, so a
# line still held at the read comes out after it.
import Base

def raw_two() -> IO(Unit):
  import "./file_read_stdout_order.c"
  import "./file_read_stdout_order.js"

def path() -> String:
  "/tmp/bend_io_file_read_stdout_order"

def closed(pair: File & Result<&1, &1, U32 & String, Unit>) -> IO(Unit):
  (file, result) = pair
  File.close(file)

def read(pair: File & Result<&1, &1, U32 & String, String>) -> IO(Unit):
  (file, result) = pair
  File.close(file)

def main() -> IO(Unit):
  do IO<Unit>:
    f : File <- IO.try(File, File.open(path(), "w"))
    w : File & Result<&1, &1, U32 & String, Unit> <- File.write(f, "x\n")
    Unit <- closed(w)
    IO.print("one")
    g : File <- IO.try(File, File.open(path(), "r"))
    r : File & Result<&1, &1, U32 & String, String> <- File.read_line(g, 64)
    Unit <- read(r)
    Unit <- raw_two()
    IO.print("three")

#|one
#|two
#|three
