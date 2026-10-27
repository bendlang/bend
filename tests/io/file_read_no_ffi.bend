# File.read, read_line, read_bytes and read_at once read through
# io_sys(), which binds libc's read and pread through bun:ffi. On a host
# without it (node) the first ask threw and the run ended. They read
# through fs now; the twin makes io_sys() throw for the reads and puts it
# back after (see file_read_no_ffi.js), so a read that still asked for
# the FFI table fails here. Only a .js twin here, so the test pins the JS
# lane. A read on an append-only file answers EBADF, so an error still
# comes back as its errno, even a read of 0 bytes.
import Base

def ffi_absent() -> IO(Unit):
  import "./file_read_no_ffi.js"

def ffi_back() -> IO(Unit):
  import "./file_read_no_ffi.js"

law path:
  String

def path():
  "/tmp/bend_io_file_read_no_ffi"

law write_go:
  for w: File & Result<&1, &1, (U32 & String), Unit>
  IO(Unit)

def write_go(w):
  (f, r) = w
  do IO<Unit>:
    u : Unit <- IO.pass(Unit, r)
    File.close(f)

law text:
  for m: File & Result<&1, &1, (U32 & String), String>
  IO(File)

def text(m):
  (f, r) = m
  match r:
    case Done{s}:
      do IO<File>:
        u : Unit <- IO.print("[" ++ s ++ "]")
        return f
    case Fail{(code, msg)}:
      do IO<File>:
        u : Unit <- IO.print("fail " ++ U32.show(code))
        return f

law bytes_line:
  for xs: List<&2, U32>
  String

def bytes_line(xs):
  match xs:
    case Nil{}:
      ""
    case [x]:
      U32.show(x)
    case x <> rest:
      U32.show(x) ++ " " ++ bytes_line(rest)

law bytes:
  for m: File & Result<&1, &1, (U32 & String), List<&2, U32>>
  IO(File)

def bytes(m):
  (f, r) = m
  do IO<File>:
    xs : List<&2, U32> <- IO.pass(List<&2, U32>, r)
    u : Unit <- IO.print(bytes_line(xs))
    return f

law main:
  IO(Unit)

def main():
  do IO<Unit>:
    f : File <- IO.try(File, File.open(path(), "w"))
    w : File & Result<&1, &1, (U32 & String), Unit> <- File.write(f, "hello\nbye")
    x : Unit <- write_go(w)
    g : File <- IO.try(File, File.open(path(), "r"))
    k : File <- IO.try(File, File.open(path(), "r"))
    h : File <- IO.try(File, File.open(path(), "a"))
    a : Unit <- ffi_absent()
    m1 : File & Result<&1, &1, (U32 & String), String> <- File.read_line(g, 64)
    g1 : File <- text(m1)
    m2 : File & Result<&1, &1, (U32 & String), List<&2, U32>> <-
      File.read_bytes(g1, 64)
    g2 : File <- bytes(m2)
    m3 : File & Result<&1, &1, (U32 & String), List<&2, U32>> <-
      File.read_at(g2, 0, 5)
    g3 : File <- bytes(m3)
    m4 : File & Result<&1, &1, (U32 & String), String> <- File.read(k, 5)
    k1 : File <- text(m4)
    m5 : File & Result<&1, &1, (U32 & String), String> <- File.read(h, 64)
    h1 : File <- text(m5)
    m6 : File & Result<&1, &1, (U32 & String), String> <- File.read(h1, 0)
    h2 : File <- text(m6)
    b : Unit <- ffi_back()
    c : Unit <- File.close(h2)
    d : Unit <- File.close(k1)
    File.close(g3)

#|[hello
#|]
#|98 121 101
#|104 101 108 108 111
#|[hello]
#|fail 9
#|fail 9
