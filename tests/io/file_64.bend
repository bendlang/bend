# Real sparse-file operations, an isolated unlinked handle on every run.
# Size halves, byte boundaries and the sequential cursor are all observable.
import Base
import ./file_binary.bend as T

def Host.file() -> IO(File):
  import "./file_64.c"
  import "./file_64.js"

def size_value(value: U32 & U32, hi: U32, lo: U32, name: String) -> IO(Unit):
  (got_hi, got_lo) = value
  T.check(name, U32.is_eq(got_hi, hi) && U32.is_eq(got_lo, lo))

def sized(pair: File & Result<&1, &1, U32 & String, U32 & U32>,
  hi: U32, lo: U32, name: String) -> IO(File):
  (f, r) = pair
  do IO<File>:
    value : U32 & U32 <- IO.pass(U32 & U32, r)
    size_value(value, hi, lo, name)
    return f

def overflow_code(+code: U32) -> IO(Unit):
  T.check("legacy size reports overflow", U32.is_eq(code, 75) || U32.is_eq(code, 84))

def overflow(r: Result<&1, &1, U32 & String, U32>) -> IO(Unit):
  match r:
    case Done{n}: IO.die(Unit, 1, "legacy size silently truncated")
    case Fail{error}:
      (code, message) = error
      overflow_code(code)

def legacy_size(pair: File & Result<&1, &1, U32 & String, U32>) -> IO(File):
  (f, r) = pair
  do IO<File>:
    overflow(r)
    return f

def bad_read(pair: File & Result<&1, &1, U32 & String, List<&2, U32>>) -> IO(File):
  (f, r) = pair
  do IO<File>:
    T.failed(List<&2, U32>, r, 22, "offset at 2^63 rejected")
    return f

def main() -> IO(Unit):
  do IO<Unit>:
    f : File <- Host.file()
    p : File & Result<&1, &1, U32 & String, U32 & U32> <- File.size64(f)
    f : File <- sized(p, 0, 0, "empty file size")
    p : File & Result<&1, &1, U32 & String, Unit> <-
      File.write_at64(f, 0, 0, [0, 1, 2, 3, 4, 5, 6, 7])
    f : File <- T.wrote(p)
    p : File & Result<&1, &1, U32 & String, List<&2, U32>> <- File.read_bytes(f, 3)
    f : File <- T.read(p, [0, 1, 2], "initial positioned write keeps cursor")
    p : File & Result<&1, &1, U32 & String, Unit> <- File.write_at64(f, 1, 0, [80, 81])
    f : File <- T.wrote(p)
    p : File & Result<&1, &1, U32 & String, Unit> <-
      File.write_at64(f, 0, 4294967295, [9, 10, 11])
    f : File <- T.wrote(p)
    p : File & Result<&1, &1, U32 & String, U32 & U32> <- File.size64(f)
    f : File <- sized(p, 1, 2, "size past 4 GiB is exact")
    p : File & Result<&1, &1, U32 & String, List<&2, U32>> <-
      File.read_at64(f, 0, 4294967294, 5)
    f : File <- T.read(p, [0, 9, 10, 11], "read crosses 4 GiB and stops at EOF")
    p : File & Result<&1, &1, U32 & String, Unit> <-
      File.write_at64(f, 2, 7, [40, 0, 255])
    f : File <- T.wrote(p)
    p : File & Result<&1, &1, U32 & String, U32 & U32> <- File.size64(f)
    f : File <- sized(p, 2, 10, "size past 8 GiB is exact")
    p : File & Result<&1, &1, U32 & String, U32> <- File.size(f)
    f : File <- legacy_size(p)
    p : File & Result<&1, &1, U32 & String, List<&2, U32>> <- File.read_at64(f, 2, 5, 8)
    f : File <- T.read(p, [0, 0, 40, 0, 255], "wide read preserves holes and binary bytes")
    p : File & Result<&1, &1, U32 & String, List<&2, U32>> <- File.read_bytes(f, 2)
    f : File <- T.read(p, [3, 4], "wide operations leave sequential cursor")
    p : File & Result<&1, &1, U32 & String, Unit> <- File.write_bytes(f, [99])
    f : File <- T.wrote(p)
    p : File & Result<&1, &1, U32 & String, List<&2, U32>> <- File.read_at64(f, 0, 4, 3)
    f : File <- T.read(p, [4, 99, 6], "sequential write still targets its own cursor")
    p : File & Result<&1, &1, U32 & String, Unit> <-
      File.write_at64(f, 2, 6, [255, 256])
    f : File <- T.bad_write(p, 22, "invalid byte rejected before writing")
    p : File & Result<&1, &1, U32 & String, List<&2, U32>> <- File.read_at64(f, 2, 5, 8)
    f : File <- T.read(p, [0, 0, 40, 0, 255], "failed byte validation preserves file")
    p : File & Result<&1, &1, U32 & String, Unit> <-
      File.write_at64(f, 2147483648, 0, [])
    f : File <- T.bad_write(p, 22, "invalid signed offset rejected for empty write")
    p : File & Result<&1, &1, U32 & String, List<&2, U32>> <-
      File.read_at64(f, 2147483648, 0, 0)
    f : File <- bad_read(p)
    p : File & Result<&1, &1, U32 & String, Unit> <- File.write_at64(f, 3, 0, [])
    f : File <- T.wrote(p)
    p : File & Result<&1, &1, U32 & String, U32 & U32> <- File.size64(f)
    f : File <- sized(p, 2, 10, "empty positioned write does not extend")
    p : File & Result<&1, &1, U32 & String, List<&2, U32>> <- File.read_at64(f, 3, 0, 0)
    f : File <- T.read(p, [], "empty wide read")
    p : File & Result<&1, &1, U32 & String, List<&2, U32>> <-
      File.read_at64(f, 2147483647, 4294967295, 0)
    f : File <- T.read(p, [], "largest signed offset accepts an empty read")
    p : File & Result<&1, &1, U32 & String, List<&2, U32>> <-
      File.read_at64(f, 2097152, 1, 1)
    f : File <- T.read(p, [], "read past EOF beyond exact Number range")
    p : File & Result<&1, &1, U32 & String, List<&2, U32>> <- File.read_bytes(f, 2)
    f : File <- T.read(p, [6, 7], "handle and cursor survive boundary failures")
    File.close(f)

#|empty file size
#|initial positioned write keeps cursor
#|size past 4 GiB is exact
#|read crosses 4 GiB and stops at EOF
#|size past 8 GiB is exact
#|legacy size reports overflow
#|wide read preserves holes and binary bytes
#|wide operations leave sequential cursor
#|sequential write still targets its own cursor
#|invalid byte rejected before writing
#|failed byte validation preserves file
#|invalid signed offset rejected for empty write
#|offset at 2^63 rejected
#|empty positioned write does not extend
#|empty wide read
#|largest signed offset accepts an empty read
#|read past EOF beyond exact Number range
#|handle and cursor survive boundary failures
