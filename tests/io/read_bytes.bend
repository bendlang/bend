# io (io_read_bytes): File.read_bytes answers a file's bytes as they
# are, 0..255 one List cell each, where File.read decodes UTF-8. A file
# is written with "Olá\n" (the á is C3 A1 on disk), read back whole and
# read back capped at 3 bytes; every lane prints the same byte lines,
# and the handle comes back beside the Result.
import Base

law path:
  String

def path():
  "/tmp/bend_io_read_bytes"

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

law write_go:
  for w: File & Result<&1, &1, (U32 & String), Unit>
  IO(Unit)

def write_go(w):
  (f, r) = w
  do IO<Unit>:
    u : Unit <- IO.pass(Unit, r)
    File.close(f)

law read_go:
  for m: File & Result<&1, &1, (U32 & String), List<&2, U32>>
  IO(Unit)

def read_go(m):
  (f, r) = m
  do IO<Unit>:
    xs : List<&2, U32> <- IO.pass(List<&2, U32>, r)
    p  : Unit <- IO.print(bytes_line(xs))
    File.close(f)

law read_max:
  for max: U32
  IO(Unit)

def read_max(max):
  do IO<Unit>:
    g : File <- IO.try(File, File.open(path(), "r"))
    m : File & Result<&1, &1, (U32 & String), List<&2, U32>> <-
      File.read_bytes(g, max)
    read_go(m)

law main:
  IO(U32)

def main():
  do IO<U32>:
    f : File <- IO.try(File, File.open(path(), "w"))
    w : File & Result<&1, &1, (U32 & String), Unit> <- File.write(f, "Olá\n")
    x : Unit <- write_go(w)
    y : Unit <- read_max(64)
    z : Unit <- read_max(3)
    return 0

#|79 108 195 161 10
#|79 108 195
