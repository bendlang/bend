# Binary IO preserves every byte, keeps the handle on failure, and leaves
# the sequential cursor unchanged when reading at an offset or asking size.
import Base

law bytes:
  for n: Nat
  for +at: U32
  List<&2, U32>

def bytes(n, at):
  match n:
    case 0n: Nil{}
    case 1n+p: at <> bytes(p, U32.add(at, 1))

law same:
  for xs: List<&2, U32>
  for ys: List<&2, U32>
  Bool

def same(xs, ys):
  match xs ys:
    case Nil{} Nil{}: True{}
    case x <> xt y <> yt: Bool.and(U32.is_eq(x, y), same(xt, yt))
    case _ _: False{}

law check:
  for name: String
  for ok: Bool
  IO(Unit)

def check(name, ok):
  match ok:
    case True{}: IO.print(name)
    case False{}: IO.die(Unit, 1, "FAIL " ++ name)

law wrote:
  for pair: File & Result<&1, &1, U32 & String, Unit>
  IO(File)

def wrote(pair):
  (file, result) = pair
  do IO<File>:
    IO.pass(Unit, result)
    return file

law sized:
  for pair: File & Result<&1, &1, U32 & String, U32>
  for want: U32
  for name: String
  IO(File)

def sized(pair, want, name):
  (file, result) = pair
  do IO<File>:
    got : U32 <- IO.pass(U32, result)
    check(name, U32.is_eq(got, want))
    return file

law read:
  for pair: File & Result<&1, &1, U32 & String, List<&2, U32>>
  for want: List<&2, U32>
  for name: String
  IO(File)

def read(pair, want, name):
  (file, result) = pair
  do IO<File>:
    got : List<&2, U32> <- IO.pass(List<&2, U32>, result)
    check(name, same(got, want))
    return file

law failed:
  for -A: Type
  for result: Result<&1, &1, U32 & String, A>
  for want: U32
  for name: String
  IO(Unit)

def failed(A, result, want, name):
  match result:
    case Done{value}: IO.die(Unit, 1, "unexpected success: " ++ name)
    case Fail{error}:
      (code, message) = error
      check(name, U32.is_eq(code, want))

law bad_write:
  for pair: File & Result<&1, &1, U32 & String, Unit>
  for want: U32
  for name: String
  IO(File)

def bad_write(pair, want, name):
  (file, result) = pair
  do IO<File>:
    failed(Unit, result, want, name)
    return file

law bad_read:
  for pair: File & Result<&1, &1, U32 & String, List<&2, U32>>
  IO(File)

def bad_read(pair):
  (file, result) = pair
  do IO<File>:
    failed(List<&2, U32>, result, 9, "read on write-only handle")
    return file

law write_invalid:
  IO(File)

def write_invalid():
  do IO<File>:
    f : File <- IO.try(File, File.open("/tmp/bend_io_file_binary", "w"))
    p : File & Result<&1, &1, U32 & String, List<&2, U32>> <-
      File.read_at(f, 0, 1)
    f : File <- bad_read(p)
    p : File & Result<&1, &1, U32 & String, Unit> <- File.write_bytes(f, [])
    f : File <- wrote(p)
    p : File & Result<&1, &1, U32 & String, Unit> <-
      File.write_bytes(f, [1, 256, 2])
    f : File <- bad_write(p, 22, "invalid byte")
    p : File & Result<&1, &1, U32 & String, U32> <- File.size(f)
    f : File <- sized(p, 0, "invalid write leaves empty file")
    return f

law write_all:
  for f: File
  IO(Unit)

def write_all(f):
  +data = bytes(256n, 0)
  do IO<Unit>:
    p : File & Result<&1, &1, U32 & String, Unit> <- File.write_bytes(f, data)
    f : File <- wrote(p)
    check("shared byte list survives write", same(data, bytes(256n, 0)))
    p : File & Result<&1, &1, U32 & String, Unit> <-
      File.write_bytes(f, [7, 4294967295])
    f : File <- bad_write(p, 22, "max U32 is not a byte")
    p : File & Result<&1, &1, U32 & String, U32> <- File.size(f)
    f : File <- sized(p, 256, "size after failed write")
    File.close(f)

law append:
  IO(Unit)

def append():
  do IO<Unit>:
    f : File <- IO.try(File, File.open("/tmp/bend_io_file_binary", "a"))
    p : File & Result<&1, &1, U32 & String, Unit> <-
      File.write_bytes(f, [0, 255])
    f : File <- wrote(p)
    File.close(f)

law open_read:
  IO(File)

def open_read():
  do IO<File>:
    f : File <- IO.try(File, File.open("/tmp/bend_io_file_binary", "r"))
    p : File & Result<&1, &1, U32 & String, Unit> <- File.write_bytes(f, [1])
    f : File <- bad_write(p, 9, "write on read-only handle")
    p : File & Result<&1, &1, U32 & String, U32> <- File.size(f)
    f : File <- sized(p, 258, "size after append")
    p : File & Result<&1, &1, U32 & String, List<&2, U32>> <-
      File.read_bytes(f, 1)
    f : File <- read(p, [0], "sequential first byte")
    return f

law read_offsets:
  for f: File
  IO(File)

def read_offsets(f):
  do IO<File>:
    p : File & Result<&1, &1, U32 & String, List<&2, U32>> <-
      File.read_at(f, 0, 256)
    f : File <- read(p, bytes(256n, 0), "all 256 byte values")
    p : File & Result<&1, &1, U32 & String, List<&2, U32>> <-
      File.read_at(f, 254, 20)
    f : File <- read(p, [254, 255, 0, 255], "short read at EOF")
    p : File & Result<&1, &1, U32 & String, List<&2, U32>> <-
      File.read_at(f, 128, 0)
    f : File <- read(p, [], "zero-length read")
    return f

law read_end:
  for f: File
  IO(Unit)

def read_end(f):
  do IO<Unit>:
    p : File & Result<&1, &1, U32 & String, List<&2, U32>> <-
      File.read_at(f, 258, 1)
    f : File <- read(p, [], "read at EOF")
    p : File & Result<&1, &1, U32 & String, List<&2, U32>> <-
      File.read_at(f, 4294967295, 1)
    f : File <- read(p, [], "read past EOF at the top offset")
    p : File & Result<&1, &1, U32 & String, U32> <- File.size(f)
    f : File <- sized(p, 258, "size preserves position")
    p : File & Result<&1, &1, U32 & String, List<&2, U32>> <-
      File.read_bytes(f, 2)
    f : File <- read(p, [1, 2], "positional reads preserve position")
    File.close(f)

law main:
  IO(Unit)

def main():
  do IO<Unit>:
    f : File <- write_invalid()
    write_all(f)
    append()
    f : File <- open_read()
    f : File <- read_offsets(f)
    read_end(f)

#|read on write-only handle
#|invalid byte
#|invalid write leaves empty file
#|shared byte list survives write
#|max U32 is not a byte
#|size after failed write
#|write on read-only handle
#|size after append
#|sequential first byte
#|all 256 byte values
#|short read at EOF
#|zero-length read
#|read at EOF
#|read past EOF at the top offset
#|size preserves position
#|positional reads preserve position
