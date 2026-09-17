# io (io_fail_keeps_handle): a failing op still threads its live
# handle: the handle rides OUTSIDE the Result, so no failure path
# can lose it. Reading a write-only handle answers Fail(EBADF), and
# the SAME handle then writes, closes and reads back -- before the
# fix the Fail branch returned no handle at all, so a failed op
# leaked its file forever and this program could not be written.
import Base

law read_fail:
  for m: File & Result<&1, &1, (U32 & String), String>
  IO(File)

def read_fail(m):
  (f, r) = m
  match r:
    case Done{data}:
      do IO<File>:
        p : Unit <- IO.print("read-succeeded")
        return f
    case Fail{error}:
      (code, message) = error
      do IO<File>:
        p : Unit <- IO.print(message)
        return f

law write_go:
  for w: File & Result<&1, &1, (U32 & String), Unit>
  IO(File)

def write_go(w):
  (f, r) = w
  do IO<File>:
    u : Unit <- IO.pass(Unit, r)
    return f

law print_go:
  for m: File & Result<&1, &1, (U32 & String), String>
  IO(U32)

def print_go(m):
  (f, r) = m
  do IO<U32>:
    data : String <- IO.pass(String, r)
    p    : Unit <- IO.print(data)
    x    : Unit <- File.close(f)
    return 0

law read_back:
  for path: String
  IO(U32)

def read_back(path):
  do IO<U32>:
    f : File <- IO.try(File, File.open(path, "r"))
    m : File & Result<&1, &1, (U32 & String), String> <- File.read(f, 64)
    print_go(m)

law main:
  IO(U32)

def main():
  do IO<U32>:
    f  : File <- IO.try(File, File.open("/tmp/bend_io_keep.tmp", "w"))
    m  : File & Result<&1, &1, (U32 & String), String> <- File.read(f, 8)
    f2 : File <- read_fail(m)
    w  : File & Result<&1, &1, (U32 & String), Unit> <- File.write(f2, "kept")
    f3 : File <- write_go(w)
    x  : Unit <- File.close(f3)
    read_back("/tmp/bend_io_keep.tmp")

#|Bad file descriptor
#|kept
