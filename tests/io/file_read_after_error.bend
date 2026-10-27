# A failed write must not make the next successful read return that error.
import Base
import ./file_binary.bend as T

def failed_write(f: File) -> IO(File):
  do IO<File>:
    p : File & Result<&1, &1, U32 & String, Unit> <- File.write(f, "!")
    T.bad_write(p, 9, "read-only write fails")

def text(p: File & Result<&1, &1, U32 & String, String>,
  want: String, name: String) -> IO(File):
  (f, r) = p
  do IO<File>:
    got : String <- IO.pass(String, r)
    T.check(name, String.eq(got, want))
    return f

def main() -> IO(Unit):
  do IO<Unit>:
    f : File <- IO.try(File, File.open("/tmp/bend_io_read_after_error", "w"))
    p : File & Result<&1, &1, U32 & String, Unit> <- File.write(f, "ab\ncd")
    f : File <- T.wrote(p)
    File.close(f)
    f : File <- IO.try(File, File.open("/tmp/bend_io_read_after_error", "r"))
    f : File <- failed_write(f)
    p : File & Result<&1, &1, U32 & String, String> <- File.read(f, 2)
    f : File <- text(p, "ab", "full text read")
    f : File <- failed_write(f)
    p : File & Result<&1, &1, U32 & String, String> <- File.read_line(f, 8)
    f : File <- text(p, "\n", "line read stops at newline")
    f : File <- failed_write(f)
    p : File & Result<&1, &1, U32 & String, List<&2, U32>> <-
      File.read_at(f, 0, 2)
    f : File <- T.read(p, [97, 98], "full positional read")
    f : File <- failed_write(f)
    p : File & Result<&1, &1, U32 & String, List<&2, U32>> <-
      File.read_at(f, 3, 8)
    f : File <- T.read(p, [99, 100], "partial positional read at EOF")
    f : File <- failed_write(f)
    p : File & Result<&1, &1, U32 & String, List<&2, U32>> <-
      File.read_bytes(f, 8)
    f : File <- T.read(p, [99, 100], "partial byte read preserves position")
    f : File <- failed_write(f)
    p : File & Result<&1, &1, U32 & String, String> <- File.read(f, 8)
    f : File <- text(p, "", "read at EOF")
    f : File <- failed_write(f)
    p : File & Result<&1, &1, U32 & String, List<&2, U32>> <-
      File.read_at(f, 0, 0)
    f : File <- T.read(p, [], "zero-length read")
    File.close(f)

#|read-only write fails
#|full text read
#|read-only write fails
#|line read stops at newline
#|read-only write fails
#|full positional read
#|read-only write fails
#|partial positional read at EOF
#|read-only write fails
#|partial byte read preserves position
#|read-only write fails
#|read at EOF
#|read-only write fails
#|zero-length read
